/**
 * Custom handler for NWL form type.
 */
public class InboundForm_NWLHandler implements InboundForm_Processor.IFormHandler {

    public List<String> validate(InboundForm_JSONParser parser) {
        return new List<String>();
    }

    public void afterBuild(InboundForm_JSONParser parser, Map<String, List<SObject>> records) {
        try {
            if (!records.containsKey('Case__c')) {
                return;
            }

            for (SObject record : records.get('Case__c')) {
                Case__c caseRecord = (Case__c) record;
                caseRecord.Case_Type__c = 'Necessary Wayleaves';
                caseRecord.Overdue_Email_Sent__c = false;

                normalizeApplicationType(caseRecord);

                caseRecord.Written_Removal_Notice_Been_Given__c =
                    caseRecord.Written_Removal_Notice_Issue_Date__c != null ? 'Yes' : 'No';
                caseRecord.Written_Termination_Notice_Been_Given__c =
                    caseRecord.Written_Termination_Notice_Issue_Date__c != null ? 'Yes' : 'No';
            }

            normalizeInstalledAssets(records);
            enrichInstalledAssets(parser, records);
            normalizeLandLocation(records);
        } catch (Exception e) {
            Logger.error('Error in NWL afterBuild: ' + e.getMessage());
            Logger.setScenario('InboundForm_NWLHandler.afterBuild');
            Logger.saveLog();
        }
    }

    public void afterPrimaryInsert(InboundForm_JSONParser parser, Id primaryCaseId,
                                    InboundForm_Processor.ProcessingResult result) {
        // No-op for NWL.
    }

    public void afterAllInserts(Id primaryCaseId, Map<String, List<SObject>> insertedRecords) {
        try {
            Case__c caseToUpdate = new Case__c(Id = primaryCaseId);
            Boolean shouldUpdate = false;

            Id applicantOrgId = getApplicantOrganisationId(primaryCaseId, insertedRecords);
            if (applicantOrgId != null) {
                try {
                    update new Case__c(
                        Id = primaryCaseId,
                        DNO__c = applicantOrgId
                    );
                } catch (Exception e) {
                    Logger.error('Error updating NWL case DNO lookup: ' + e.getMessage());
                    Logger.setScenario('InboundForm_NWLHandler.afterAllInserts');
                    Logger.saveLog();
                }
            }

            Id paymentId = getFirstRecordId(insertedRecords, 'Payment__c');
            if (paymentId != null) {
                caseToUpdate.Payment__c = paymentId;
                shouldUpdate = true;
            }

            Id relatedLandId = getFirstRecordId(insertedRecords, 'Land__c');
            if (relatedLandId != null) {
                caseToUpdate.Related_Land__c = relatedLandId;
                shouldUpdate = true;
            }

            Id objectorId = getPartyIdByTypeAndApplicationPartyId(
                insertedRecords,
                'Individual',
                'NWL_OBJECTOR'
            );
            if (objectorId != null) {
                caseToUpdate.Objector__c = objectorId;
                shouldUpdate = true;
            }

            Id representativeId = getPartyIdByTypeAndApplicationPartyId(
                insertedRecords,
                'Representative',
                'NWL_REPRESENTATIVE'
            );
            if (representativeId != null) {
                caseToUpdate.Representative__c = representativeId;
                shouldUpdate = true;
            }

            Id landownerId = getPartyIdByTypeAndApplicationPartyId(
                insertedRecords,
                'Landowner',
                'NWL_LANDOWNER'
            );
            if (landownerId != null) {
                caseToUpdate.Landowner__c = landownerId;
                shouldUpdate = true;
            }

            linkApplicantContactToApplicant(primaryCaseId);

            linkLandToSiteAddress(insertedRecords);

            if (!shouldUpdate) {
                return;
            }

            try {
                update caseToUpdate;
            } catch (Exception e) {
                Logger.error('Error updating NWL case lookups: ' + e.getMessage());
                Logger.setScenario('InboundForm_NWLHandler.afterAllInserts');
                Logger.saveLog();
            }
        } catch (Exception e) {
            Logger.error('Unexpected error in NWL afterAllInserts: ' + e.getMessage());
            Logger.setScenario('InboundForm_NWLHandler.afterAllInserts');
            Logger.saveLog();
        }
    }

    private static void normalizeApplicationType(Case__c caseRecord) {
        if (!String.isBlank(caseRecord.Application_Type__c)) {
            if (caseRecord.Application_Type__c.equalsIgnoreCase('Existing line')) {
                caseRecord.Application_Type__c = 'Existing Line';
            } else if (caseRecord.Application_Type__c.equalsIgnoreCase('New line')) {
                caseRecord.Application_Type__c = 'New Line';
            }
        }

        caseRecord.Type_Of_NWL_That_Existed__c =
            mapNwlWayleaveType(caseRecord.Type_Of_NWL_That_Existed__c);

        caseRecord.Legislation_Applicable__c =
            mapNwlGroundsForApplication(caseRecord.Legislation_Applicable__c);
    }

    @TestVisible
    private static String mapNwlWayleaveType(String value) {
        if (String.isBlank(value)) {
            return value;
        }

        if (value.equalsIgnoreCase('inherited_necessary_wayleave')) {
            return Label.NWL_Inherited_Necessary_Wayleave;
        }
        if (value.equalsIgnoreCase('implied_wayleave')) {
            return Label.NWL_Implied_Wayleave;
        }
        if (value.equalsIgnoreCase('wayleave')) {
            return Label.NWL_Wayleave;
        }

        return value;
    }

    @TestVisible
    private static String mapNwlGroundsForApplication(String value) {
        if (String.isBlank(value)) {
            return value;
        }

        if (value.equalsIgnoreCase('no_wayleave_exists') || value.containsIgnoreCase('exist')) {
            return Label.NWL_no_wayleave_exists;
        } else if (value.equalsIgnoreCase('wayleave_has_been_terminated') || value.equalsIgnoreCase('wayleave_termination') || value.equalsIgnoreCase('wayleave_terminated') || value.containsIgnoreCase('terminated')) {
            return Label.NWL_Wayleave_has_been_terminated;
        } else if (value.equalsIgnoreCase('wayleave_expired') || value.containsIgnoreCase('expir')) {
            return Label.NWL_Wayleave_has_Expired;
        }

        return value;
    }

    private static void normalizeLandLocation(Map<String, List<SObject>> records) {
        if (!records.containsKey('Land__c')) {
            return;
        }

        for (SObject record : records.get('Land__c')) {
            Land__c landRecord = (Land__c) record;
            if (String.isBlank(landRecord.Land_Location__c)) {
                continue;
            }

            if (landRecord.Land_Location__c.equalsIgnoreCase('england')) {
                landRecord.Land_Location__c = 'England';
            } else if (landRecord.Land_Location__c.equalsIgnoreCase('wales')) {
                landRecord.Land_Location__c = 'Wales';
            }
        }
    }

    private static void normalizeInstalledAssets(Map<String, List<SObject>> records) {
        if (!records.containsKey('Asset_Information__c')) {
            return;
        }

        for (SObject record : records.get('Asset_Information__c')) {
            Asset_Information__c assetRecord = (Asset_Information__c) record;
            if (String.isBlank(assetRecord.Line_Voltage__c)) {
                continue;
            }

            if (assetRecord.Line_Voltage__c.equalsIgnoreCase('240/415V')) {
                assetRecord.Line_Voltage__c = '240/415v';
            } else if (assetRecord.Line_Voltage__c.equalsIgnoreCase('6.6KV')) {
                assetRecord.Line_Voltage__c = '6.6kV';
            } else if (assetRecord.Line_Voltage__c.equalsIgnoreCase('11KV')) {
                assetRecord.Line_Voltage__c = '11kV';
            } else if (assetRecord.Line_Voltage__c.equalsIgnoreCase('20KV')) {
                assetRecord.Line_Voltage__c = '20kV';
            } else if (assetRecord.Line_Voltage__c.equalsIgnoreCase('25KV')) {
                assetRecord.Line_Voltage__c = '25kV';
            } else if (assetRecord.Line_Voltage__c.equalsIgnoreCase('33KV')) {
                assetRecord.Line_Voltage__c = '33kV';
            } else if (assetRecord.Line_Voltage__c.equalsIgnoreCase('66KV')) {
                assetRecord.Line_Voltage__c = '66kV';
            } else if (assetRecord.Line_Voltage__c.equalsIgnoreCase('132KV')) {
                assetRecord.Line_Voltage__c = '132kV';
            } else if (assetRecord.Line_Voltage__c.equalsIgnoreCase('275KV')) {
                assetRecord.Line_Voltage__c = '275kV';
            } else if (assetRecord.Line_Voltage__c.equalsIgnoreCase('400KV')) {
                assetRecord.Line_Voltage__c = '400kV';
            }
        }
    }

    private static void enrichInstalledAssets(
            InboundForm_JSONParser parser,
            Map<String, List<SObject>> records) {
        if (parser == null || !records.containsKey('Asset_Information__c')) {
            return;
        }

        List<Map<String, Object>> rawInstalledAssets =
            parser.getObjectList('sections.assets.installed_assets');
        if (rawInstalledAssets.isEmpty()) {
            return;
        }

        Map<String, Map<String, Object>> installedAssetsById = new Map<String, Map<String, Object>>();
        for (Map<String, Object> rawAsset : rawInstalledAssets) {
            Object assetIdObj = rawAsset.get('asset_id');
            if (assetIdObj == null) {
                continue;
            }

            String assetId = String.valueOf(assetIdObj);
            if (!String.isBlank(assetId)) {
                installedAssetsById.put(assetId, rawAsset);
            }
        }

        for (SObject record : records.get('Asset_Information__c')) {
            Asset_Information__c assetRecord = (Asset_Information__c) record;
            if (String.isBlank(assetRecord.TORI_NOI_Code__c)) {
                continue;
            }

            Map<String, Object> rawAsset = installedAssetsById.get(assetRecord.TORI_NOI_Code__c);
            if (rawAsset == null) {
                continue;
            }

            List<String> lineTypes = extractStringList(rawAsset.get('line_types'));
            String mappedLineTypes = mapLineTypes(lineTypes, assetRecord.Line_Voltage__c);
            if (!String.isBlank(mappedLineTypes)) {
                assetRecord.Line_Type_Multi__c = mappedLineTypes;
            }

            String description = buildAssetDescription(rawAsset.get('component_descriptions'), lineTypes);
            if (!String.isBlank(description)) {
                assetRecord.Description__c = description;
            }
        }
    }

    private static List<String> extractStringList(Object rawListObj) {
        List<String> values = new List<String>();
        if (!(rawListObj instanceof List<Object>)) {
            return values;
        }

        for (Object item : (List<Object>) rawListObj) {
            if (item != null) {
                String strValue = String.valueOf(item);
                if (!String.isBlank(strValue)) {
                    values.add(strValue);
                }
            }
        }

        return values;
    }

    private static String buildAssetDescription(Object rawDescriptionsObj, List<String> lineTypes) {
        if (!(rawDescriptionsObj instanceof Map<String, Object>)) {
            return null;
        }

        Map<String, Object> descriptionMap = (Map<String, Object>) rawDescriptionsObj;
        List<String> orderedDescriptions = new List<String>();
        Set<String> seen = new Set<String>();

        for (String lineType : lineTypes) {
            if (!descriptionMap.containsKey(lineType)) {
                continue;
            }
            String descriptionText = String.valueOf(descriptionMap.get(lineType));
            if (!String.isBlank(descriptionText) && !seen.contains(descriptionText)) {
                orderedDescriptions.add(descriptionText);
                seen.add(descriptionText);
            }
        }

        if (orderedDescriptions.isEmpty()) {
            for (Object valueObj : descriptionMap.values()) {
                String descriptionText = String.valueOf(valueObj);
                if (!String.isBlank(descriptionText) && !seen.contains(descriptionText)) {
                    orderedDescriptions.add(descriptionText);
                    seen.add(descriptionText);
                }
            }
        }

        if (orderedDescriptions.isEmpty()) {
            return null;
        }

        String combined = String.join(orderedDescriptions, ' | ');
        return combined.length() > 255 ? combined.substring(0, 255) : combined;
    }

    private static String mapLineTypes(List<String> lineTypes, String lineVoltage) {
        if (lineTypes.isEmpty()) {
            return null;
        }

        List<String> mappedValues = new List<String>();
        Set<String> seen = new Set<String>();
        Boolean highVoltage = isHighVoltage(lineVoltage);

        for (String lineType : lineTypes) {
            String mappedValue = mapSingleLineType(lineType, highVoltage);
            if (!String.isBlank(mappedValue) && !seen.contains(mappedValue)) {
                mappedValues.add(mappedValue);
                seen.add(mappedValue);
            }
        }

        return mappedValues.isEmpty() ? null : String.join(mappedValues, ';');
    }

    private static String mapSingleLineType(String lineType, Boolean highVoltage) {
        if (String.isBlank(lineType)) {
            return null;
        }

        if (lineType == 'Distribution') {
            return 'Distribution';
        }
        if (lineType == 'Transmission') {
            return 'Transmission';
        }

        if (lineType == 'overhead_line_wooden_pole_stay') {
            return highVoltage
                ? 'HV overhead line + poles + stays'
                : 'LV overhead line + poles + stays';
        }
        if (lineType == 'overhead_line_wooden_pole') {
            return highVoltage
                ? 'HV overhead line + wooden poles'
                : 'LV overhead line + wooden poles';
        }
        if (lineType == 'overhead_line_steel_tower') {
            return highVoltage
                ? 'HV overhead line + steel towers'
                : 'LV overhead line + steel towers';
        }
        if (lineType == 'underground_cable') {
            return highVoltage
                ? 'HV underground cable'
                : 'LV underground cable';
        }
        if (lineType == 'overhead_line') {
            return highVoltage
                ? 'HV overhead line'
                : 'LV overhead line';
        }
        if (lineType == 'underground_cable_wooden_pole_stay') {
            return highVoltage
                ? 'HV underground cable + poles + stays'
                : 'LV underground cable + poles + stays';
        }
        if (lineType == 'underground_cable_wooden_pole') {
            return highVoltage
                ? 'HV underground cable + wooden poles'
                : 'LV underground cable + wooden poles';
        }
        if (lineType == 'wooden_pole') {
            return 'Wooden poles';
        }
        if (lineType == 'steel_tower') {
            return 'Steel towers';
        }
        if (lineType == 'stay') {
            return 'Stays';
        }

        return null;
    }

    private static Boolean isHighVoltage(String lineVoltage) {
        if (String.isBlank(lineVoltage)) {
            return true;
        }

        String normalized = lineVoltage.toLowerCase().replace(' ', '');
        // NWL payloads use 240/415V for low-voltage assets.
        return !normalized.contains('240/415');
    }

    private static Boolean linkLandToSiteAddress(Map<String, List<SObject>> insertedRecords) {
        if (!insertedRecords.containsKey('Land__c') || !insertedRecords.containsKey('Address__c')) {
            return false;
        }

        Id landId;
        for (SObject record : insertedRecords.get('Land__c')) {
            if (record.Id != null) {
                landId = record.Id;
                break;
            }
        }

        if (landId == null) {
            return false;
        }

        Id siteAddressId;
        for (SObject record : insertedRecords.get('Address__c')) {
            Address__c addr = (Address__c) record;
            if (addr.Id != null && addr.Application_Party_Identification__c == 'NWL_SITE_ADDRESS') {
                siteAddressId = addr.Id;
                break;
            }
        }

        if (siteAddressId == null) {
            return false;
        }

        try {
            update new Land__c(
                Id = landId,
                Site_Address__c = siteAddressId
            );
            return true;
        } catch (Exception e) {
            Logger.error('Error linking NWL land to site address: ' + e.getMessage());
            Logger.setScenario('InboundForm_NWLHandler.linkLandToSiteAddress');
            Logger.saveLog();
            return false;
        }
    }

    private static Id getFirstRecordId(Map<String, List<SObject>> insertedRecords, String objectName) {
        if (!insertedRecords.containsKey(objectName)) {
            return null;
        }

        for (SObject record : insertedRecords.get(objectName)) {
            if (record.Id != null) {
                return record.Id;
            }
        }
        return null;
    }

    private static Id getPartyIdByType(Map<String, List<SObject>> insertedRecords, String partyType) {
        if (!insertedRecords.containsKey('Party__c')) {
            return null;
        }

        for (SObject record : insertedRecords.get('Party__c')) {
            Party__c party = (Party__c) record;
            if (party.Id != null && party.Party_Type__c == partyType) {
                return party.Id;
            }
        }
        return null;
    }

    private static Id getPartyIdByTypeAndApplicationPartyId(
            Map<String, List<SObject>> insertedRecords,
            String partyType,
            String applicationPartyId) {
        if (!insertedRecords.containsKey('Party__c')) {
            return null;
        }

        for (SObject record : insertedRecords.get('Party__c')) {
            Party__c party = (Party__c) record;
            if (party.Id != null
                    && party.Party_Type__c == partyType
                    && party.Application_Party_Id__c == applicationPartyId) {
                return party.Id;
            }
        }
        return null;
    }

    private static Id getApplicantOrganisationId(
            Id primaryCaseId,
            Map<String, List<SObject>> insertedRecords) {
        Id applicantOrgId = getPartyIdByType(insertedRecords, 'DNO');
        if (applicantOrgId != null) {
            return applicantOrgId;
        }

        List<Party__c> applicantParties = [
            SELECT Id
            FROM Party__c
            WHERE Case__c = :primaryCaseId
            AND Party_Type__c = 'DNO'
            LIMIT 1
        ];

        return applicantParties.isEmpty() ? null : applicantParties[0].Id;
    }

    private static void linkApplicantContactToApplicant(Id primaryCaseId) {
        List<Party__c> parties = [
            SELECT Id, Party_Type__c, Representative__c, Application_Party_Id__c
            FROM Party__c
            WHERE Case__c = :primaryCaseId
        ];

        Id applicantPartyId;
        String applicantLinkKey;
        Id applicantContactPartyId;

        for (Party__c party : parties) {
            if (party.Party_Type__c == 'DNO') {
                applicantPartyId = party.Id;
                applicantLinkKey = party.Application_Party_Id__c;
                break;
            }
        }

        if (applicantPartyId == null || String.isBlank(applicantLinkKey)) {
            return;
        }

        for (Party__c party : parties) {
            if (party.Id != applicantPartyId
                    && party.Application_Party_Id__c == applicantLinkKey) {
                applicantContactPartyId = party.Id;
                break;
            }
        }

        if (applicantContactPartyId == null) {
            return;
        }

        try {
            update new Party__c(
                Id = applicantPartyId,
                Representative__c = applicantContactPartyId
            );
        } catch (Exception e) {
            Logger.error('Error linking NWL applicant contact to applicant: ' + e.getMessage());
            Logger.setScenario('InboundForm_NWLHandler.linkApplicantContactToApplicant');
            Logger.saveLog();
        }
    }
}