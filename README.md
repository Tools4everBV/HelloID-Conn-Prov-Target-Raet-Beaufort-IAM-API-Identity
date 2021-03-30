# **Work-In-Progress - Untested**

### HelloID-Conn-Prov-Target-Raet-Users
This connector is able to write back the identity of a provisioned user (to another target like Azure AD or MS AD) to the user of Raet Beaufort. This field can be used in Beaufort for, by example, Single Sign-On purposes. Please keep in mind that for now, only the AccountCreate or AccountUpdate is triggering the possible change of the identity. (Disable, Delete and Enable are not neccesarry)

Also keep in mind that this endpoint will be migrated to the new IAM-API later on.

### Configuration
Please make your provisioned system dependant on this Users Target Connector and make sure that the values needed to be written back are stored on the account data (e.g UserPrincipalName).

### Custom Connector Configuration
Please add the following JSON Custom Connector Configuration to this Target System and fill the Configuration Tab with the correct values of the Beaufort Environment.

[
  {
    "key": "connection.clientId",
    "type": "input",
    "defaultValue": "",
    "templateOptions": {
      "label": "Client Id",
      "placeholder": "Enter the client Id here",
      "description": "",
      "required": true
    }
  },
  {
    "key": "connection.clientSecret",
    "type": "input",
    "defaultValue": "",
    "templateOptions": {
      "label": "Client Secret",
      "type": "password",
      "placeholder": "Enter the Client Secret here",
      "required": true
    }
  },
  {
    "key": "connection.tenantId",
    "type": "input",
    "defaultValue": "",
    "templateOptions": {
      "label": "Tenant Id",
      "placeholder": "Enter the Tenant Id here",
      "description": "Optional. Not required in most implementations.",
      "required": false
    }
  }
]

### More information
More information about the Users endpoint of the Raet Users Endpoint can be found on:
https://community.raet.com/developers-community/w/iam-api/2695/iam-endpoints-users
