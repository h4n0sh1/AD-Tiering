# AD-Tiering
[![Project Status: Active -- The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![GitHub release](https://img.shields.io/github/release/h4n0sh1/ad-tiering.svg)](https://github.com/h4n0sh1/AD-Tiering)
[![PSAnalyzer](https://github.com/h4n0sh1/ad-tiering/actions/workflows/powershell.yml/badge.svg?branch=main&event=push)](https://github.com/h4n0sh1/ad-tiering/actions/workflows/powershell.yml)
![GitHub commit activity](https://img.shields.io/github/commit-activity/w/h4n0sh1/ad-tiering)
[![Github Downloads](https://img.shields.io/github/downloads/h4n0sh1/ad-tiering/total)](https://github.com/h4n0sh1/AD-Tiering)
[![License](https://img.shields.io/github/license/h4n0sh1/ad-tiering.svg)](https://github.com/h4n0sh1/ad-tiering/blob/master/LICENSE)

## Introduction

This repo means to provide minimalistic yet efficient utilities to help security teams save time in their journey of hardening existing Active Directory infrastructures.<br>
The philosophy is to make as few assumptions as possible about the way each organization wants to implement it's tiering architecture, hence the choice of an XML based declaration. 

## Features 

- Exporting and replicating an Active Directory Tree to / from a CSV file
- Creating new Tiering Organizational Unit from an XML file declaration
- Replicating Active Directory Tree structure under the newly created Tiering Organizational Unit
- Linking existing GPO

## Usage 

These tools have been developped with minimal impact in mind, as we do measure the intrisical risk associated with these highly sensitive environments. This means that a typical workflow would encapsulate the following : 

| Script              | Purpose                                   | Recommended Environment |
| --------------------| ------------------------------------------|-------------------------| 
| Exports-ADTree.ps1  | Exports all AD Tree objects in CSV format | RSAT, RODC              |
| Export-GPOLinks.ps1 | Exports all GPO Links in CSV format       | RSAT, RODC              |
| Copy-ADTree.ps1     | Replicates AD Tree objects from CSV file  | Virtual Machine / Test  |
| New-TieringOU.ps1   | Creates Tiering OUs based on XML template | Virtual Machine / Test  |
| Populate-TieringOU.ps1 | Replicates AD Ous under Tiering OUs    | Virtual Machine / Test  |
| Copy-GPOLinks.ps1   | Replicates GPO Links under Tiering OUs    | Virtual Machine / Test  |

## Requirements

None aside from a running version of Windows Server 2019+. <br>
Further tests required to assess backwards compatibility. 
