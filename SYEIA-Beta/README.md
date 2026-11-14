# SYEIA-Beta: Salesforce Application

A Salesforce-based application for managing cases, applications, and document approvals. This project is built using Salesforce DX (SFDX) and includes Lightning Web Components (LWC), Apex classes, and automated workflows.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Linting & Formatting](#linting--formatting)
- [Deployment](#deployment)
- [Key Features](#key-features)
- [Scripts](#scripts)
- [Contributing](#contributing)
- [License](#license)

## Overview

SYEIA-Beta is a comprehensive Salesforce application that provides:

- **Case Management**: Streamlined case handling and status tracking
- **Application Processing**: Automated application status updates and workflow management
- **Document Approval**: Approval processes for document submissions
- **Business Logic**: Automated business days calculations and custom business rules
- **Community Features**: Community landing pages and user management

This project uses modern Salesforce development practices with:
- Salesforce DX for version control and deployment
- Lightning Web Components for UI
- Apex for backend logic
- Jest for unit testing
- ESLint for code quality
- Prettier for code formatting

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (v14 or later)
- **npm** (v6 or later)
- **Salesforce CLI** (sfdx-cli)
  ```bash
  npm install -g @salesforce/cli
  ```
- **Git**
- A **Salesforce Developer Org** or Scratch Org

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/DESNZ-SYEIA-Salesforce-Beta.git
   cd SYEIA-Beta
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Authenticate with Salesforce**
   ```bash
   sfdx org login web --alias myorg
   ```

4. **Create a Scratch Org** (for development)
   ```bash
   sfdx org create scratch --definition-file config/project-scratch-def.json --alias syeia-dev
   ```

5. **Push metadata to org**
   ```bash
   sfdx project deploy start --target-org syeia-dev
   ```

## Project Structure

```
force-app/main/default/
+-- applications/           # Salesforce applications (app builder)
+-- approvalProcesses/      # Approval workflow definitions
+-- brandingSets/           # Custom branding configurations
+-- classes/                # Apex classes and tests
�   +-- Application_StatusUpdateQueueable.cls
�   +-- ApplicationStatusService.cls
�   +-- BusinessDaysCalculator.cls
�   +-- CaseTriggerHandler.cls
�   +-- ChangePasswordController.cls
�   +-- *Test.cls          # Corresponding test classes
+-- components/             # Visualforce components
+-- flexipages/            # Lightning page layouts
+-- flows/                 # Flow automation definitions
+-- labels/                # Custom labels
+-- layouts/               # Page layouts
+-- lwc/                   # Lightning Web Components
+-- objects/               # Custom objects
+-- pages/                 # Visualforce pages
+-- profiles/              # Profile definitions
+-- permissionsets/        # Permission set definitions
+-- tabs/                  # Custom tabs
+-- triggers/              # Apex triggers
+-- workflows/             # Workflow automation

config/
+-- project-scratch-def.json  # Scratch org configuration

manifest/
+-- package.xml            # Deployment manifest
+-- destructiveChanges/    # Metadata to remove during deployment

scripts/
+-- apex/                  # Example Apex scripts
+-- soql/                  # Example SOQL queries
```

## Development Setup

### Authorize an Organization

```bash
# Authenticate with a production or sandbox org
sfdx org login web --set-default

# Or create a new scratch org
sfdx org create scratch --definition-file config/project-scratch-def.json --set-default
```

### Deploy Changes

```bash
# Deploy all metadata
sfdx project deploy start

# Deploy specific metadata
sfdx project deploy start --metadata ApexClass:CaseTriggerHandler
```

### Retrieve Metadata

```bash
# Retrieve all metadata from org
sfdx project retrieve start

# Retrieve specific components
sfdx project retrieve start --metadata LightningComponentBundle:*
```

## Testing

### Experience Cloud Case Management Suite

The `caseManagementSuite` LWC provides a searchable, paginated list of accessible
`Case__c` records and read-only case reference, type, and status details. It uses
UI API, not system-mode Apex. Salesforce enforces object permissions, field
permissions, and record sharing. Guest users cannot load the list.

The existing **Case Management Suite** Lightning console app cannot be hosted
inside Experience Cloud. This component is a site-native alternative for case
lists and details, not a copy of the internal dashboards, utility bar, flows,
or record-page overrides. The internal app is unchanged.

Create and publish the new site in the target org:

1. Enable Digital Experiences in Setup and configure the org's domain if needed.
2. In **All Sites**, create a **Build Your Own (LWR)** site named
   **Case Management Suite**, with a unique URL prefix such as `case-management`.
   Site provisioning, domain selection, and publishing are org setup steps;
   no site has been provisioned by adding this component to the repository.
3. Deploy the component and its access metadata to an org containing `Case__c`:

   ```powershell
   sf project deploy start --target-org <org-alias> --source-dir force-app/main/default/lwc/caseManagementSuite --source-dir force-app/main/default/objects/Case__c/listViews/Experience_Cases.listView-meta.xml --source-dir force-app/main/default/permissionsets/Experience_Case_Reader.permissionset-meta.xml
   ```

4. Confirm the external-user licence supports `Case__c` and UI API. Assign
   **Experience Case Reader** to the intended users and add that permission set
   to the site's membership in Experience Workspaces. Permission sets are
   additive; this set does not remove broader permissions granted elsewhere.
5. Keep external case sharing **Private**. Configure a narrowly scoped Sharing
   Set or external sharing rule appropriate to the licence and your approved
   contact/account-to-case relationship. Do not use an unrestricted sharing
   rule. The component does not decide which records belong to an applicant.
   The **Experience Cases** list view is visible to customer portal users;
   list-view visibility does not grant record access. For other external
   licence types, configure list-view visibility for the intended members.
6. In Experience Builder, make the home page available to authenticated members
   only and add the custom **Case Management Suite** component. Configure site
   login, publish the site, and activate it when access testing is complete.
7. Test as two external users with different shared cases. Each must see only
   their permitted cases, including in search and subsequent pages. Check an
   empty account, field restrictions, mobile layout, and a guest session before
   publishing to your wider audience.

After provisioning, retrieve the generated Network, CustomSite, and
DigitalExperienceBundle metadata into source control using the actual site
developer names. These are org-generated and are not included here.

Run the component's focused unit tests after installing Node.js and dependencies:

```powershell
npm run test:unit -- --runInBand --runTestsByPath force-app/main/default/lwc/caseManagementSuite/__tests__/caseManagementSuite.test.js
```

### Run Unit Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:unit:watch

# Run tests with coverage
npm run test:unit:coverage

# Debug tests
npm run test:unit:debug
```

### Apex Testing

Run Apex tests in your org:

```bash
sfdx apex test run --code-coverage-by-class --output-dir coverage --result-format json
```

## Linting & Formatting

### ESLint

Check code quality for Lightning Web Components and Aura components:

```bash
# Run linter
npm run lint

# The linter checks: **/{aura,lwc}/**/*.js
```

### Prettier

Format code across all file types:

```bash
# Format all files
npm run prettier

# Verify formatting without changes
npm run prettier:verify
```

These commands format:
- .cls, .cmp, .component (Apex)
- .css, .html, .js, .json (Web)
- .md, .page, .trigger (Documentation)
- .xml, .yaml, .yml (Config)

## Deployment

### Deploy to Production

1. **Create a deployment package**
   ```bash
   sfdx project deploy start --target-org production
   ```

2. **Monitor deployment**
   ```bash
   sfdx project deploy report --use-most-recent
   ```

### Validate Before Deployment

```bash
sfdx project deploy validate --target-org production
```

## Key Features

### Application Status Management
- ApplicationStatusService.cls: Core service for managing application status updates
- Application_StatusUpdateQueueable.cls: Asynchronous processing of status updates
- BusinessDaysCalculator.cls: Calculates business days excluding weekends and holidays

### Case Management
- CaseTriggerHandler.cls: Handles case-related business logic
- CaseTriggerHelper.cls: Helper methods for case operations
- Case_Management_Suite.app: Complete case management application

### Authentication & Access Control
- ChangePasswordController.cls: Password management functionality
- Custom permission sets and profiles for role-based access

### Document Processing
- Approval workflows for document submissions
- Document metadata and routing logic
- Integration with Salesforce approval processes

### Community Features
- CommunitiesLandingController.cls: Community portal landing page
- Community-specific customizations and branding

## Scripts

| Script | Purpose |
|--------|---------|
| 
pm test | Run unit tests |
| 
pm run test:unit:watch | Run tests in watch mode |
| 
pm run test:unit:debug | Debug tests |
| 
pm run test:unit:coverage | Generate test coverage report |
| 
pm run lint | Lint LWC and Aura components |
| 
pm run prettier | Format all files |
| 
pm run prettier:verify | Verify file formatting |
| 
pm run prepare | Setup Husky git hooks |
| 
pm run precommit | Pre-commit linting and formatting |

## Git Hooks

This project uses **Husky** for git hooks and **lint-staged** for pre-commit checks:

- Automatically formats staged files with Prettier
- Runs ESLint on LWC/Aura files
- Runs Jest tests on changed LWC components

To bypass hooks (not recommended):
```bash
git commit --no-verify
```

## Troubleshooting

### Scratch Org Issues
```bash
# Delete a scratch org
sfdx org delete --target-org syeia-dev

# Recreate the scratch org
sfdx org create scratch --definition-file config/project-scratch-def.json --alias syeia-dev
```

### Authentication Failures
```bash
# Clear cached authentication
sfdx org logout --all

# Re-authenticate
sfdx org login web --alias myorg
```

### Deployment Conflicts
```bash
# Check deployment status
sfdx project deploy report --use-most-recent

# Retrieve latest metadata from org
sfdx project retrieve start
```

## Contributing

1. Create a feature branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit
   ```bash
   git commit -m "Description of changes"
   ```

3. Push to your branch
   ```bash
   git push origin feature/your-feature-name
   ```

4. Create a Pull Request with a clear description of your changes

### Code Standards

- Follow Salesforce code style guidelines
- Write unit tests for new Apex classes (aim for >80% coverage)
- Lint and format code before committing
- Document complex business logic with comments
- Use meaningful variable and method names

## API Version

This project uses **Salesforce API v64.0**. Check sfdx-project.json for the current version.

To update:
```bash
sfdx project default set sourceApiVersion 65.0
```

## License

See LICENSE file for details.

## Support

For issues, questions, or contributions, please:
1. Check existing issues in the repository
2. Create a new issue with detailed information
3. Contact the development team

---

**Last Updated:** 2026-08-26  
**Version:** 1.0.0  
**Status:** Beta
