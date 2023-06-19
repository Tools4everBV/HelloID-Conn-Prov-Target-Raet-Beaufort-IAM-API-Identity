| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |

| :warning: Warning |
|:---------------------------|
| The latest version of this connector requires **new api credentials**. To get these, please follow the [Visma documentation on how to register the App and grant access to client data](https://community.visma.com/t5/Kennisbank-Youforce-API/Visma-Developer-portal-een-account-aanmaken-applicatie/ta-p/527059).  
<br />
<p align="center">
  <img src="https://www.tools4ever.nl/connector-logos/vismaraet-logo.png" width="500">
</p>

## Versioning
| Version | Description | Date |
| - | - | - |
| 1.1.2   | Performance and logging upgrades | 2022/10/25  |
| 1.1.1   | Updated checking of identity value | 2021/08/06  |
| 1.1.0   | Implementation updates | 2021/04/01  |
| 1.0.0   | Initial release | 2020/11/12  |

<!-- TABLE OF CONTENTS -->
## Table of Contents
- [Versioning](#versioning)
- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
- [Introduction](#introduction-1)
- [Getting started](#getting-started)
  - [Connection settings](#connection-settings)
  - [Prerequisites](#prerequisites)
    - [Remarks](#remarks)
- [Getting help](#getting-help)
- [HelloID docs](#helloid-docs)


## Introduction
By using this connector you will have the ability to update the 'identity' field of Raet users, using the RAET IAM API.

This connector is able to write back the identity of a provisioned user (to another target like Azure AD or MS AD) to the user of Raet Beaufort. This field can be used in Beaufort for single Sign-On purposes. Please keep in mind that for now, only the AccountCreate or AccountUpdate is triggering the possible change of the identity. (Disable, Delete and Enable are not neccesarry)

Also keep in mind that this endpoint will be migrated to the new IAM-API later on.

More information about the Users endpoint of the Raet Users Endpoint can be found on:
- https://community.visma.com/t5/Kennisbank-Youforce-API/IAM-user-endpoint/ta-p/430073
- https://vr-api-integration.github.io/SwaggerUI/IAM%20Users.html

## Introduction
By using this connector you will have the ability to update the 'identity' field of Raet users, using the RAET IAM API.

This connector is able to write back the identity of a provisioned user (to another target like Azure AD or MS AD) to the user of Raet Beaufort. This field can be used in Beaufort for single Sign-On purposes. 
Also keep in mind that this endpoint will be migrated to the new IAM-API later on.

More information about the Users endpoint of the Raet Users Endpoint can be found on:
- https://community.visma.com/t5/Kennisbank-Youforce-API/IAM-user-endpoint/ta-p/430073
- https://vr-api-integration.github.io/SwaggerUI/IAM%20Users.html
- 
The HelloID connector consists of the template scripts shown in the following table.

| Action                          | Action(s) Performed   | Comment   | 
| ------------------------------- | --------------------- | --------- |
| create.ps1                      | Update RAET user  |           |
| update.ps1                      | Update RAET user  |           |
| delete.ps1                      | Update RAET user  | Clear the unique fields, since the values have to be unique in RAET  |

## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting           | Description                                                   | Example value                         |
| ----------------- | ------------------------------------------------------------- | ------------------------------------- |
| Client Id         | The Client id for this Raet environment                       | A1bCdefghifjkL2MnOPQrsT3u45V6wx7Y     |
| Client Secret     | The Client secret for this Raet environment                   | 7aBcdeFgHijkLmN                       |
| Tenant Id         | The Tenant id for this Raet environment                       | 1234567                               |

### Prerequisites

- [ ] HelloID Provisioning agent (cloud or on-prem).
- [ ] Enabling of the User endpoints.
  - By default, the User endpoints aren't "enabled". This has to be requested at Raet.
- [ ] ClientID, ClientSecret and tenantID
  - Since we are using the API we neet the ClientID, ClientSecret and tenantID to authenticate with RAET IAM-API Webservice.
- [ ] Dependent account data in HelloID.
  - Please make your provisioned system dependent on this Users Target Connector and make sure that the values needed to be written back are stored on the account data (e.g UserPrincipalName).

#### Remarks
- Only the 'identity' field can be updated, no other fields are (currently) supported.
  > When the value in Raet equals the value in HelloID, the action will be skipped (no update will take place).
- Currently (08-12-2022) Changes you make with this connector through the API are not visible within the Youforce portal. If you want to check if the update is succesfull please retreive the edited user or try the SSO connection.

## Getting help
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012558020-Configure-a-custom-PowerShell-target-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs
The official HelloID documentation can be found at: https://docs.helloid.com/
