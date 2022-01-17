| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |
<br />

<!-- TABLE OF CONTENTS -->
## Table of Contents
- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
- [Getting started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Connection settings](#connection-settings)
- [contents](#contents)
- [Remarks](#remarks)
- [Getting help](#getting-help)
- [HelloID Docs](#helloid-docs)


## Introduction
By using this connector you will have the ability to update the 'identity' field of Raet users, using the RAET IAM API.

This connector is able to write back the identity of a provisioned user (to another target like Azure AD or MS AD) to the user of Raet Beaufort. This field can be used in Beaufort for, by example, Single Sign-On purposes. Please keep in mind that for now, only the AccountCreate or AccountUpdate is triggering the possible change of the identity. (Disable, Delete and Enable are not neccesarry)

Also keep in mind that this endpoint will be migrated to the new IAM-API later on.

More information about the Users endpoint of the Raet Users Endpoint can be found on:
https://community.raet.com/developers-community/w/iam-api/2695/iam-endpoints-users

## Getting started

### Prerequisites

- [ ] Enabling of the User endpoints

  By default, the User endpoints aren't "enabled". This has to be requested at Raet.

- [ ] ClientID, ClientSecret and tenantID

  Since we are using the API we neet the ClientID, ClientSecret and tenantID to authenticate with RAET IAM-API Webservice.

- [ ] Dependent account data in HelloID

  Please make your provisioned system dependent on this Users Target Connector and make sure that the values needed to be written back are stored on the account data (e.g UserPrincipalName).

### Connection settings

| Setting           | Description                                                   | Example value                         |
| ----------------- | ------------------------------------------------------------- | ------------------------------------- |
| Client Id         | The Client id for this Raet environment                       | A1bCdefghifjkL2MnOPQrsT3u45V6wx7Y     |
| Client Secret     | The Client secret for this Raet environment                   | 7aBcdeFgHijkLmN                       |
| Tenant Id         | The Tenant id for this Raet environment                       | 1234567                               |

## contents

| File/Directory  | Description                                                  |
| ---------------------------------------------------------- | ------------------------------------------------------------ |
| create.ps1      | Correlates to the employee/user based on the employeeId and updates the 'idenity field' (with the AD UPN)     |
| update.ps1      | Correlates to the employee/user based on the employeeId and updates the 'idenity field' (with the AD UPN)     |
| delete.ps1      | Correlates to the employee/user based on the employeeId and updates the 'idenity field' (with an empty value) |


## Remarks
- Only the 'identity' field can be updated, no other fields are (currently) supported.
  
> When the value in Raet equals the value in HelloID, the action will be skipped (no update will take place).


## Getting help
> _For more information on how to configure a HelloID PowerShell scheduled task, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/115003253294-Create-Custom-Scheduled-Tasks) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID Docs
The official HelloID documentation can be found at: https://docs.helloid.com/
