
# HelloID-Conn-Prov-Target-Raet-Beaufort-IAM-API-Identity

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://github.com/Tools4everBV/HelloID-Conn-Prov-Target-Raet-Beaufort-IAM-API-Identity/blob/main/Logo.png?raw=true">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-Raet-Beaufort-IAM-API-Identity](#helloid-conn-prov-target-raet-beaufort-iam-api-identity)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Supported features](#supported-features)
  - [Getting started](#getting-started)
    - [HelloID Icon URL](#helloid-icon-url)
    - [Requirements](#requirements)
    - [Connection settings](#connection-settings)
    - [Correlation configuration](#correlation-configuration)
    - [Field mapping](#field-mapping)
    - [Account Reference](#account-reference)
  - [Remarks](#remarks)
    - [Supported identity field](#supported-identity-field)
    - [Identity clearing (14-02-2024)](#identity-clearing-14-02-2024)
    - [Portal visibility (08-12-2022)](#portal-visibility-08-12-2022)
  - [Development resources](#development-resources)
    - [API endpoints](#api-endpoints)
    - [API documentation](#api-documentation)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-Raet-Beaufort-IAM-API-Identity_ is a _target_ connector. Raet Beaufort provides REST APIs that allow you to interact with user identity data. This connector correlates existing users and writes the identity value back to Raet Beaufort for use with single sign-on.

## Supported features

The following features are available:

| Feature                                   | Supported | Actions                | Remarks                                             |
| ----------------------------------------- | --------- | ---------------------- | --------------------------------------------------- |
| **Account Lifecycle**                     | ✅         | create, update, delete | Only correlate account and update the Identity user |
| **Permissions**                           | ❌         | -                      | -                                                   |
| **Resources**                             | ❌         | -                      | -                                                   |
| **Entitlement Import: Accounts**          | ❌         | -                      | -                                                   |
| **Entitlement Import: Permissions**       | ❌         | -                      | -                                                   |
| **Governance Reconciliation Resolutions** | ❌         | -                      | -                                                   |

## Getting started

### HelloID Icon URL

URL of the icon used for the HelloID Provisioning target system.

```text
https://raw.githubusercontent.com/Tools4everBV/HelloID-Conn-Prov-Target-Raet-Beaufort-IAM-API-Identity/refs/heads/main/Icon.png
```

### Requirements

- **API credentials**: Register an application in the Visma Developer portal and grant access to client data. See the [Visma documentation](https://community.visma.com/t5/Kennisbank-Youforce-API/Visma-Developer-portal-een-account-aanmaken-applicatie/ta-p/527059).
- **User endpoints**: Request that the IAM API user endpoints are enabled for the tenant; they are not enabled by default.
- **Dependent account data**: Make the provisioned system dependent on this target and ensure the identity value to write back (for example, a user principal name) is available on the account data.

### Connection settings

The following settings are used to connect to the API.

| Setting                  | Description                                                                                                                   | Mandatory |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------- | --------- |
| Client ID                | The client ID for the IAM API, created when registering the application in the Visma Developer portal.                        | Yes       |
| Client Secret            | The client secret for the IAM API, created when registering the application in the Visma Developer portal.                    | Yes       |
| Tenant ID                | The tenant ID for the Raet tenant. It is available in the Visma Developer portal after the invitation code has been accepted. | No        |
| Only update on correlate | When enabled, the Raet Beaufort user is updated only when the account is correlated.                                          | No        |

### Correlation configuration

The correlation configuration specifies which properties are used to match an existing account in Raet Beaufort to a person in HelloID.

| Setting                   | Value                             |
| ------------------------- | --------------------------------- |
| Enable correlation        | `True`                            |
| Person correlation field  | `PersonContext.Person.ExternalId` |
| Account correlation field | `employeeId`                      |

> [!TIP]
> For more information on correlation, see the [HelloID correlation documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html).

### Field mapping

The field mapping can be imported by using the [_fieldMapping.json_](./fieldMapping.json) file.

### Account Reference

The account reference is populated with the correlated user's `employeeId`.

## Remarks

### Supported identity field

Only the `identity` field can be updated. When the value in Raet Beaufort already matches the value in HelloID, the update is skipped.

### Identity clearing (14-02-2024)

The Youforce endpoint does not currently allow the identity to be emptied. Configure a fallback value such as `ExternalID@Domain.com` if an identity value is required during the delete action.

### Portal visibility (08-12-2022)

Changes made through the API may not be visible in the Youforce portal. To verify an update, retrieve the edited user through the API or test the single sign-on connection.

## Development resources

### API endpoints

The following endpoints are used by the connector:

| Endpoint                                            | HTTP method | Description                    |
| --------------------------------------------------- | ----------- | ------------------------------ |
| `https://connect.visma.com/connect/token`           | POST        | Retrieve an access token       |
| `/iam/v1.0/users(employeeId={employeeId})`          | GET         | Retrieve a user by employee ID |
| `/iam/v1.0/users(employeeId={employeeId})/identity` | PATCH       | Update the user's identity     |

### API documentation

- [IAM user endpoint information](https://community.visma.com/t5/Kennisbank-Youforce-API/IAM-user-endpoint/ta-p/430073)
- [Youforce IAM API Swagger documentation](https://api.youforce.com/documentation/index.html?urls.primaryName=Youforce.IAM.Api#/Users)

## Getting help

> [!TIP]
> For more information on configuring a HelloID PowerShell connector, see the [PowerShell V2 target system documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html).

## HelloID docs

The official HelloID documentation can be found at: [https://docs.helloid.com/](https://docs.helloid.com/)
