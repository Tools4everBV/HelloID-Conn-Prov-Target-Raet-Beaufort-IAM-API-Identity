
# HelloID-Conn-Prov-Target-Raet-Beaufort-IAM-API-Identity


> [!WARNING]
> This script is not tested. Only dryCoded! fieldMapping.json will be added after the release.

> [!WARNING]
> This script is for the new powershell connector. Make sure to use the mapping and correlation keys like mentionded in this readme. For more information, please read our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html).

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="./Logo.png">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-Raet-Beaufort-IAM-API-Identity](#helloid-conn-prov-target-raet-beaufort-iam-api-identity)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Provisioning PowerShell V2 connector](#provisioning-powershell-v2-connector)
      - [Correlation configuration](#correlation-configuration)
      - [Field mapping](#field-mapping)
    - [Connection settings](#connection-settings)
    - [Prerequisites](#prerequisites)
    - [Remarks](#remarks)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-Raet-Beaufort-IAM-API-Identity_ is a _target_ connector. _Raet-Beaufort_ provides a set of REST API's that allow you to programmatically interact with its data. The HelloID connector uses the API endpoints listed in the table below.

| Endpoint                                          | Description |
| ------------------------------------------------- | ----------- |
| /iam/v1.0/users(employeeId={employeeId})          | GET user    |
| /iam/v1.0/users(employeeId={employeeId})/identity | PATCH user  |

This connector is able to write back the identity of a provisioned user (to another target like Azure AD or MS AD) to the user of Raet Beaufort. This field can be used in Beaufort for single Sign-On purposes. 
Also keep in mind that this endpoint will be migrated to the new IAM-API later on.

More information about the Users endpoint of the Raet Users Endpoint can be found on:
- [Community visma](https://community.visma.com/t5/Kennisbank-Youforce-API/IAM-user-endpoint/ta-p/430073)
- [Swagger](https://vr-api-integration.github.io/SwaggerUI/IAM%20Users.html)



The following lifecycle actions are available:

| Action             | Description                          |
| ------------------ | ------------------------------------ |
| create.ps1         | Correlation on person                |
| delete.ps1         | Empty configured field(s) on person  |
| update.ps1         | Update configured field(s) on person |
| configuration.json | Default _configuration.json_         |
| fieldMapping.json  | Default _fieldMapping.json_          |

## Getting started

### Provisioning PowerShell V2 connector

#### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _{connectorName}_ to a person in _HelloID_.

To properly setup the correlation:

1. Open the `Correlation` tab.

2. Specify the following configuration:

    | Setting                   | Value                             |
    | ------------------------- | --------------------------------- |
    | Enable correlation        | `True`                            |
    | Person correlation field  | `PersonContext.Person.ExternalId` |
    | Account correlation field | ``                                |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

#### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

### Connection settings

The following settings are required to connect to the API.

| Setting        | Description                                                                                                                                                      | Mandatory |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| Client ID      | The Client ID to connect with the IAM API (created when registering the App in in the Visma Developer portal).                                                   | Yes       |
| Client Secret  | The Client Secret to connect with the IAM API (created when registering the App in in the Visma Developer portal).                                               | Yes       |
| Tenant ID      | The Tenant ID to specify to which Raet tenant to connect with the IAM API (available in the Visma Developer portal after the invitation code has been accepted). | Yes       |
| UpdateOnUpdate | If you also want to update the user on a update account                                                                                                          |           |

### Prerequisites

> [!IMPORTANT]
> The latest version of this connector requires **new api credentials**. To get these, please follow the [Visma documentation](https://community.visma.com/t5/Kennisbank-Youforce-API/Visma-Developer-portal-een-account-aanmaken-applicatie/ta-p/527059) on how to register the App and grant access to client data.  
- [ ] Enabling of the User endpoints.
  - By default, the User endpoints aren't "enabled". This has to be requested at Raet.
- [ ] ClientID, ClientSecret and tenantID
  - Since we are using the API we need the ClientID, ClientSecret and tenantID to authenticate with RAET IAM-API Webservice.
- [ ] Dependent account data in HelloID.
  - Please make your provisioned system dependent on this Users Target Connector and make sure that the values needed to be written back are stored on the account data (e.g UserPrincipalName).

### Remarks
> [!TIP]
> Only the 'identity' field can be updated, no other fields are (currently) supported.
> 
> When the value in Raet equals the value in HelloID, the action will be skipped (no update will take place).

> [!NOTE]
> Currently (08-12-2022) Changes you make with this connector through the API are not visible within the Youforce portal. If you want to check if the update is succesfull please retreive the edited user or try the SSO connection.

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
