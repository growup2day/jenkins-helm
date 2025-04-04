import hudson.security.GlobalMatrixAuthorizationStrategy;
import hudson.security.Permission;
import hudson.security.PermissionGroup;
import jenkins.model.Jenkins;

// Provides a helper function to setup anonymous access
//
// Usage in JCasC
//
// JCasC:
//   configScripts:
//     anonymous-access: |
//       groovy:
//          - script: |
//             {{- .Files.Get "groovy-lib/anonymous-access-helper.groovy" | nindent 6 }}
//             setAnonymousAccess(["Overall-Read", "Job-Read"] as String[])
//
// **Note**
// Unfortunately this cannot be achieved with configuration-as-code like the following (which would have been nicer)
//   jenkins:
//     # Configure Global Security > Authorization
//     authorizationStrategy:
//       globalMatrix:
//         permissions:
//           - "Overall/Read:anonymous"
//           - "Job/Read:anonymous"
// Because each time the above configuration is loaded, is it going to overwrite all the existing permissions created by
// the openshift login plugin, requiring all the users to log out and log back in.
def setAnonymousAccess(
  String[] grantedPermissions
) {
  def _isGranted = { String[][] granted, Permission required ->
    String permissionGroupName = required.group.title.toString(Locale.US).trim();
    String permissionName = required.name.trim();

    return granted.any { permissionGroupName.equalsIgnoreCase(it[0]) && permissionName.equalsIgnoreCase(it[1]) };
  }

  def parsedPermissions = grantedPermissions
      .collect { it.trim().split("-") }
      .findAll { it.length == 2 } as String[][];

  def existingAuthMgr = (GlobalMatrixAuthorizationStrategy)Jenkins.getInstance().getAuthorizationStrategy();
  def newAuthMgr = new GlobalMatrixAuthorizationStrategy();
  List<Permission> permissions = Permission.getAll();
  Set<String> usersGroups = existingAuthMgr.getGroups();

  // copy over existing user group permissions except for anonymous
  for (Permission p : permissions) {
    for (String userGroup : usersGroups) {
      if (userGroup != "anonymous" && existingAuthMgr.hasPermission(userGroup, p)) {
        newAuthMgr.add(p, userGroup);
      }
    }
  }

  // set permissions for anonymous user
  for (Permission p : permissions) {
    if (_isGranted(parsedPermissions, p)) {
      newAuthMgr.add(p, "anonymous");
    }
  }
  
  Jenkins.getInstance().setAuthorizationStrategy(newAuthMgr);
  Jenkins.getInstance().save();
}
