# This python script would monitor the JCasC mount path for changes and trigger JCasC reload when it happens.
import functools
import sys
import pyinotify
import requests
import time

# When mounting a config map on a pod, Kubernetes places the actual files under a subfolder named with release datetime.
# And use symbolic link to map the files to the target folder. For example:
#   $ ls -al /var/lib/jenkins-jcasc/
#   total 0
#   drwxrwsrwx. 3 root 1001060000 134 Nov 23 12:14 .
#   drwxr-xr-x. 1 root root        68 Nov 23 12:10 ..
#   drwxr-sr-x. 2 root 1001060000  81 Nov 23 12:14 ..2021_11_22_23_14_46.632973838
#   lrwxrwxrwx. 1 root 1001060000  31 Nov 23 12:14 ..data -> ..2021_11_22_23_14_46.632973838
#   lrwxrwxrwx. 1 root root        22 Nov 23 12:10 k8s-clouds.yaml -> ..data/k8s-clouds.yaml
#   lrwxrwxrwx. 1 root root        24 Nov 23 12:10 master-proxy.yaml -> ..data/master-proxy.yaml
#   lrwxrwxrwx. 1 root root        26 Nov 23 12:10 system-message.yaml -> ..data/system-message.yaml
#
# Then during a rollout with only config map change, Kubernetes does the following:
#   1. create a new subfolder named with release datetime (e.g. /var/lib/jenkins-jcasc/..2021_11_22_24_21_05.106982740)
#      and add the new files under it
#   2. create a new symlink of /var/lib/jenkins-jcasc/..data_tmp that points to the new subfolder
#   3. move the symlink from /var/lib/jenkins-jcasc/..data_tmp to /var/lib/jenkins-jcasc/..data (overwriting the old symlink)
#   4. delete the old datetime subfolder (/var/lib/jenkins-jcasc/..2021_11_22_23_14_46.632973838)
# The following code tries to detect action #3 above and triggers JCasC reload when it happens.
# Note - There is a delay between when the deployment config is updated and when the corresponding files mounted in the
# pod is updated. It's usually under 1 min, but occasionally a bit longer than that, so the timeout is set to 90 seconds

# Watched events - first 2 only for logging purpose
mask = pyinotify.IN_CREATE | pyinotify.IN_MOVED_FROM | pyinotify.IN_MOVED_TO

def triggerReload():
  # sleep for 1 second for change to settle down
  time.sleep(1)
  print ("Trigerring JCasC reload")
  # "jenkins.jcascReloadToken" is going to be replaced by Helm with the actual token
  response = requests.post("http://localhost:8080/reload-configuration-as-code/?casc-reload-token={{ include "jenkins.jcascReloadToken" $ }}")
  print(response)
  if not response.ok:
    print("\n    !!!FAILURE!!!\nFailed to reload JCasC. Please make sure that all the configurations and Job DSL scripts are valid")
    print("Check Jenkins log for detailed error messages\n")

class EventHandler(pyinotify.ProcessEvent):
  def process_IN_CREATE(self, event):
    print ("Detected creation:", event.pathname)

  def process_IN_MOVED_FROM(self, event):
    print ("Detected moved from:", event.pathname)

  def process_IN_MOVED_TO(self, event):
    print ("Detected moved to:", event.pathname)
    triggerReload()
    # exit the script to avoid unnecessary wait
    notifier.stop()
    sys.exit(0)

scriptTimeout = 90
startTime = time.time()
def onLoop(notifier):
  now = time.time()
  elapsedSeconds = now - startTime
  if elapsedSeconds > scriptTimeout:
    # exit the script to avoid unnecessary wait
    print("Timed out waiting for JCasC config change. Trigger a reload anyway in case we missed it.")
    triggerReload()
    # exit the script to avoid unnecessary wait
    notifier.stop()
    sys.exit(0)

# Instantiate a new WatchManager (will be used to store watches).
wm = pyinotify.WatchManager()
# Associate this WatchManager with a Notifier (will be used to report and process events).
handler = EventHandler()
notifier = pyinotify.Notifier(wm, handler, timeout=1000)
# Watch the JCasC mount path (to be replaced by Helm) for the specified events
wm.add_watch('{{ include "jenkins.jcascMountPath" $ }}/', mask)
# Start watch
notifier.loop(callback=onLoop)