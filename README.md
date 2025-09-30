# HelloID-Conn-Prov-Target-Xedule-employees


> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://partner.afas.nl/file/download/default/F2DF898CDDD64CD4A9CCD9A15B2262A8/Xedule-logomark-pos.png">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-Xedule-employees](#helloid-conn-prov-target-xedule-employees)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Supported  features](#supported--features)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Connection settings](#connection-settings)
    - [Correlation configuration](#correlation-configuration)
    - [Field mapping](#field-mapping)
    - [Account Reference](#account-reference)
  - [Remarks](#remarks)
    - [InDienst / UitDienst](#indienst--uitdienst)
  - [Development resources](#development-resources)
    - [API endpoints](#api-endpoints)
    - [API documentation](#api-documentation)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-Xedule-employees_ is a _target_ connector. _Xedule-employees_ provides a set of REST API's that allow you to programmatically interact with its data.

## Supported  features

The following features are available:

| Feature                                   | Supported | Actions                                 | Remarks |
| ----------------------------------------- | --------- | --------------------------------------- | ------- |
| **Account Lifecycle**                     | ✅         | Create, Update, Enable, Disable, Delete |         |
| **Permissions**                           | ❌         | -                                       |         |
| **Resources**                             | ❌         | -                                       |         |
| **Entitlement Import: Accounts**          | ✅         | -                                       |         |
| **Entitlement Import: Permissions**       | ❌         | -                                       |         |
| **Governance Reconciliation Resolutions** | ✅         | -                                       |         |

## Getting started

### Prerequisites

- The information from the Connection setting Table: [Connection settings](#connection-settings)

### Connection settings

The following settings are required to connect to the API.

| Setting                | Description                                      | Mandatory |
| ---------------------- | ------------------------------------------------ | --------- |
| OreId                  | The OreId to connect to the API                  | Yes       |
| Customer               | The Customer to connect to the API               | Yes       |
| OcpApimSubscriptionKey | The OcpApimSubscriptionKey to connect to the API | Yes       |
| ClientId               | The ClientId to connect to the API               | Yes       |
| ClientSecret           | The ClientSecret to connect to the API           | Yes       |
| BaseUrl                | The URL to the API                               | Yes       |
| TokenUrl               | The URL to retrieve the API accessToken          | Yes       |

### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _Xedule-employees_ to a person in _HelloID_.

| Setting                   | Value                             |
| ------------------------- | --------------------------------- |
| Enable correlation        | `True`                            |
| Person correlation field  | `PersonContext.Person.ExternalId` |
| Account correlation field | `ReferentieID`                    |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

### Account Reference

The account reference is populated with the property `id` property from _Xedule-employees_

## Remarks
Current state of the connector:

### InDienst / UitDienst
- The property InDienst is used to enable and disable accounts. This property requires a from and to range and grants you account access to all the employments in this range.
- Its not clear if the property UitDienst is necessary to disable an account. If it is not necessary this property can be deleted in the enable and disable scripts.

## Development resources

### API endpoints

The following endpoints are used by the connector

| Endpoint                                                                               | Description                              |
| -------------------------------------------------------------------------------------- | ---------------------------------------- |
| /employee-teams/api/Medewerker/ore/:oreId?customer=:Customer                           | Retrieve user information by referenceId |
| /employee-teams/api/Medewerker/ore/:oreId/referenceKey/:referenceId?customer=:Customer | CRUD user actions                        |
| /employee-teams/api/Medewerker/ore/:oreId/id/:id?customer=:Customer                    | Retrieve user information by Id          |

### API documentation

[https://developer.connect.xedule.nl/api-details#api=employee-teams-prod&operation=Medewerker_GetMedewerker](https://developer.connect.xedule.nl/api-details#api=employee-teams-prod&operation=Medewerker_GetMedewerker)

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com/forum/helloid-connectors/provisioning/5379-helloid-conn-prov-target-xedule-employees)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/

