# HelloID-Conn-Prov-Target-Raet-IAM-API-Users
This connector is able to write back the identity of a provisioned user (to another target like Azure AD or MS AD) to the user of Raet Beaufort. This field can be used in Beaufort for, by example, Single Sign-On purposes.

# Configuration
Please make your provisioned system dependant on this IAM-API Users Target Connector and make sure that the values needed to be written back are stored on the account data (e.g UserPrincipalName).

# Custom Connector Configuration
Please add the Custom Connector Configuration to this Target System.

[
  {
    "key": "clientid",
    "type": "input",
    "defaultValue": "",
    "templateOptions": {
      "label": "Raet ClientID",
      "required": true
    }
    },
    {
    "key": "clientsecret",
    "type": "input",
    "defaultValue": "",
    "templateOptions": {
      "label": "Raet Client Secret",
      "required": true
    }
    },
    {
    "key": "tenantid",
    "type": "input",
    "defaultValue": "",
    "templateOptions": {
      "label": "Raet TenantId",
      "required": true
    }
    }
}

# More information
More information about the Users endpoint of the Raet IAM-API can be found on:
https://community.raet.com/developers-community/w/iam-api/2695/iam-endpoints-users
