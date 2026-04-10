/**
 * Custom handler for S37 form type. Implements form-specific validation and post-processing logic.
 */
public class InboundForm_S37Handler implements InboundForm_Processor.IFormHandler {
    
    /**
     * Validate S37-specific business rules
     */
    public List<String> validate(InboundForm_JSONParser parser) {
        List<String> errors = new List<String>();
        
        validateRoutes(parser, errors);
        
        return errors;
    }
    
    /**
     * Post-build processing for S37
     */
    public void afterBuild(InboundForm_JSONParser parser, Map<String, List<SObject>> records) {
        processCaseRecords(parser, records);
        processPartyRecords(records);
        processRouteRecords(parser, records);
    }
    
    /**
     * Post-primary-insert processing for S37
     * Handles records that need the primary Case ID, such as Related_Case__c records
     */
    public void afterPrimaryInsert(InboundForm_JSONParser parser, Id primaryCaseId, 
                                    InboundForm_Processor.ProcessingResult result) {
        processApplicationRelations(parser, primaryCaseId, result);
    }
    
    /**
     * Post-all-inserts processing for S37
     * Handles updates that need child record IDs, such as setting DNO__c on Case
     */
    public void afterAllInserts(Id primaryCaseId, Map<String, List<SObject>> insertedRecords) {
        
        Case__c caseToUpdate = new Case__c(Id = primaryCaseId);

        setDNOOnCase(caseToUpdate, insertedRecords);
        setPaymentOnCase(caseToUpdate, insertedRecords);
        setPostConsultationsCase(caseToUpdate, insertedRecords);

        // Update the Case with the DNO Party Id, Payment Id and PostConsultation Id
        try {
            update caseToUpdate;
            System.debug(LoggingLevel.INFO, 'Set DNO__c, Payment__c, Post_Consultation__c on Case ' +  caseToUpdate);
        } catch (Exception e) {
            Logger.error('Error setting DNO, Payment and PostConsultation on Case: ' + e.getMessage());
            Logger.setScenario('InboundForm_S37Handler.afterAllInserts');
            Logger.saveLog();
            System.debug(LoggingLevel.ERROR, 'Error setting DNO, Payment and PostConsultation on Case: ' + e.getMessage());
        }
    }
    
    // ========================================================================
    // VALIDATION METHODS
    // ========================================================================
    
    /**
     * Validate route requirements
     */
    private void validateRoutes(InboundForm_JSONParser parser, List<String> errors) {
        List<Map<String, Object>> routes = parser.getObjectList('sections.location.routes');
        
        if (routes.isEmpty()) {
            errors.add('S37 applications require at least one route');
            return;
        }
        
        for (Integer i = 0; i < routes.size(); i++) {
            Map<String, Object> route = routes[i];
            String routeName = (String) route.get('routeName');
            if (String.isBlank(routeName)) {
                routeName = 'Route ' + (i + 1);
            }
            
            Object gridPoints = route.get('gridPoints');
            
            if (gridPoints == null) {
                errors.add('Route "' + routeName + '" has no grid points');
            } else if (gridPoints instanceof List<Object>) {
                List<Object> points = (List<Object>) gridPoints;
                if (points.size() < 2) {
                    errors.add('Route "' + routeName + '" must have at least 2 grid points ' +
                        '(found ' + points.size() + ')');
                }
            }
        }
    }
    
    // ========================================================================
    // POST-BUILD PROCESSING
    // ========================================================================
    
    /**
     * Process Case records after build
     */
    private void processCaseRecords(InboundForm_JSONParser parser, 
                                     Map<String, List<SObject>> records) {
        if (!records.containsKey('Case__c')) {
            return;
        }
        
        for (SObject record : records.get('Case__c')) {
            Case__c caseRecord = (Case__c) record;
            
            // Set Case Type
            caseRecord.Case_Type__c = 'Section 37';
            
            // Set fee status
            caseRecord.Application_Fee_Paid__c = 'Yes';
            
            // Initialize email sent flag
            caseRecord.Overdue_Email_Sent__c = false;
            
            // Handle EIA fields
            handleEIAFields(parser, caseRecord);
            
            // Handle date fields
            handleDateFields(parser, caseRecord);
        }
    }
    
    /**
     * Process Party records after build
     */
    private void processPartyRecords(Map<String, List<SObject>> records) {
        if (!records.containsKey('Party__c')) {
            return;
        }
        
        for (SObject record : records.get('Party__c')) {
            Party__c party = (Party__c) record;
            if (party.Is_Primary__c == true) {
                party.Party_Type__c = 'DNO';
            }
        }
    }
    
    /**
     * Process Route records after build
     * Enriches Route__c records with tolerance data from sections.sensitiveAreaChecks
     */
    private void processRouteRecords(InboundForm_JSONParser parser, 
                                      Map<String, List<SObject>> records) {
        if (!records.containsKey('Route__c')) {
            return;
        }
        
        // Get tolerance values from sections.sensitiveAreaChecks
        Boolean toleranceRequired = parser.getBoolean('sections.sensitiveAreaChecks.tolerance_required');
        Decimal toleranceValue = parser.getDecimal('sections.sensitiveAreaChecks.tolerance_value');
        
        // Convert Yes/No boolean to string for ToleranceRequired__c field
        String toleranceRequiredValue = null;
        if (toleranceRequired != null) {
            toleranceRequiredValue = toleranceRequired ? 'Yes' : 'No';
        }
        
        // Apply tolerance values to all Route records
        for (SObject record : records.get('Route__c')) {
            Route__c route = (Route__c) record;
            
            if (toleranceRequiredValue != null) {
                route.Tolerance_Required__c = toleranceRequiredValue;
            }
            
            if (toleranceValue != null) {
                route.Tolerance__c = toleranceValue;
            }
        }
    }
    
    /**
     * Handle EIA field logic
     */
    private void handleEIAFields(InboundForm_JSONParser parser, Case__c caseRecord) {
        Boolean isEiaDevelopment = parser.getBoolean('sections.eiaFees.is_eia_development');
        Boolean screeningOnly = parser.getBoolean('sections.eiaFees.screening_only');
        
        if (screeningOnly == true) {
            // Both scenarios require Subject_To_An_EIA__c = 'Yes'
            caseRecord.Subject_To_An_EIA__c = 'Yes';
            
            if (isEiaDevelopment == true) {
                // is_eia_development = true AND screening_only = true
                caseRecord.Full_EIA_Process_or_Screening_Opinion__c = 'Full EIA Process';
            } else if (isEiaDevelopment == false) {
                // is_eia_development = false AND screening_only = true
                caseRecord.Full_EIA_Process_or_Screening_Opinion__c = 'EIA Screening Opinion';
            }
        } else {
            // Scenario where screening_only = false
            caseRecord.Subject_To_An_EIA__c = 'No';
        }
    }
    
    /**
     * Handle combined date fields (year + month)
     */
    private void handleDateFields(InboundForm_JSONParser parser, Case__c caseRecord) {
        // Earliest start date
        caseRecord.Earliest_Expected_Start_Date__c = buildDateFromYearMonth(
            parser.getString(
                'sections.projectDetails.overview.application_project_overview.earliest_work_start_date_year'),
            parser.getString(
                'sections.projectDetails.overview.application_project_overview.earliest_work_start_date_month')
        );
        
        // Latest start date
        caseRecord.Latest_Expected_Start_Date__c = buildDateFromYearMonth(
            parser.getString(
                'sections.projectDetails.overview.application_project_overview.latest_work_start_date_year'),
            parser.getString(
                'sections.projectDetails.overview.application_project_overview.latest_work_start_date_month')
        );
    }
    
    /**
     * Build a date from separate year and month values
     */
    private Date buildDateFromYearMonth(String year, String month) {
        if (String.isBlank(year) || String.isBlank(month)) {
            return null;
        }
        
        try {
            return Date.newInstance(
                Integer.valueOf(year),
                Integer.valueOf(month),
                1
            );
        } catch (Exception e) {
            Logger.error('Error building date from year=' + year + ', month=' + month);
            Logger.error('Exception message: ' + e.getMessage());
            Logger.setScenario('InboundForm_Processor.buildDateFromYearMonth');
            Logger.saveLog();
            System.debug(LoggingLevel.WARN, 
                'Error building date from year=' + year + ', month=' + month + 
                ': ' + e.getMessage());
            return null;
        }
    }
    
    // ========================================================================
    // APPLICATION RELATIONS PROCESSING
    // ========================================================================
    
    /**
     * Process application_relations to create Related_Case__c records
     * Links the current Case to existing Cases found by AWS_Application_Id__c
     */
    private void processApplicationRelations(InboundForm_JSONParser parser, Id parentCaseId,
                                              InboundForm_Processor.ProcessingResult result) {
        // Get application_relations from JSON
        List<Map<String, Object>> relations = parser.getObjectList(
            'sections.projectDetails.overview.application_relations');
        
        if (relations == null || relations.isEmpty()) {
            return;
        }
        
        // Collect all related_application_ids to query
        Set<String> relatedAwsIds = new Set<String>();
        Map<String, Map<String, Object>> relationsByAwsId = new Map<String, Map<String, Object>>();
        
        for (Map<String, Object> relation : relations) {
            String relatedAwsId = (String) relation.get('related_application_id');
            if (String.isNotBlank(relatedAwsId)) {
                relatedAwsIds.add(relatedAwsId);
                relationsByAwsId.put(relatedAwsId, relation);
            }
        }
        
        if (relatedAwsIds.isEmpty()) {
            return;
        }
        
        // Query for existing Case__c records matching the AWS Application IDs
        Map<String, Id> awsIdToCaseIdMap = new Map<String, Id>();
        try {
            List<Case__c> existingCases = [
                SELECT Id, AWS_Application_Id__c 
                FROM Case__c 
                WHERE AWS_Application_Id__c IN :relatedAwsIds
            ];
            
            for (Case__c c : existingCases) {
                awsIdToCaseIdMap.put(c.AWS_Application_Id__c, c.Id);
            }
        } catch (Exception e) {
            Logger.error('Error querying for related cases: ' + e.getMessage());
            Logger.setScenario('InboundForm_S37Handler.processApplicationRelations');
            Logger.saveLog();
            System.debug(LoggingLevel.ERROR, 'Error querying for related cases: ' + e.getMessage());
            result.addWarning('Error querying for related cases: ' + e.getMessage());
            return;
        }
        
        // Create Related_Case__c records for found cases, track missing ones
        List<Related_Case__c> relatedCasesToCreate = new List<Related_Case__c>();
        List<String> missingAwsIds = new List<String>();
        
        for (String awsId : relatedAwsIds) {
            if (awsIdToCaseIdMap.containsKey(awsId)) {
                // Found the related case - create the Related_Case__c record
                Id childCaseId = awsIdToCaseIdMap.get(awsId);
                Map<String, Object> relationData = relationsByAwsId.get(awsId);
                
                Related_Case__c relatedCase = new Related_Case__c();
                relatedCase.Parent_Case__c = parentCaseId;
                relatedCase.Child_Case__c = childCaseId;
                
                relatedCasesToCreate.add(relatedCase);
            } else {
                // Related case not found - track for partial success
                missingAwsIds.add(awsId);
            }
        }
        
        // Add Related_Case__c records to be inserted
        if (!relatedCasesToCreate.isEmpty()) {
            result.addPostPrimaryRecords('Related_Case__c', relatedCasesToCreate);
        }
        
        // Add warnings for missing cases (triggers Partial Success status)
        for (String missingAwsId : missingAwsIds) {
            result.addWarning('Failed to find Case using AWS Id ' + missingAwsId);
        }
    }
    
    // ========================================================================
    // DNO PROCESSING
    // ========================================================================
    
    /**
     * Set the DNO__c field on Case__c to the primary Party__c record
     */
    private void setDNOOnCase(Case__c primaryCase, Map<String, List<SObject>> insertedRecords) {
        if (!insertedRecords.containsKey('Party__c')) {
            return;
        }

        Id dnoPartyId;
        Id repPartyId;

        for (SObject record : insertedRecords.get('Party__c')) {
            Party__c party = (Party__c) record;

            if (party.Is_Primary__c && party.Id != null) {
                dnoPartyId = party.Id;
                break;
            } else if (repPartyId == null && party.Id != null) {
                repPartyId = party.Id;
            }
        }

        try {
            if (dnoPartyId == null && repPartyId != null) {
                List<Party__c> parties = [
                    SELECT Id
                    FROM Party__c
                    WHERE Representative__c = :repPartyId
                    AND Case__c != null
                    AND Is_Primary__c = true
                    LIMIT 1
                ];

                if (!parties.isEmpty()) {
                    dnoPartyId = parties[0].Id;
                }
            }

            if (dnoPartyId != null) {
                primaryCase.DNO__c = dnoPartyId;
                System.debug(LoggingLevel.INFO, 
                    'Set DNO__c on Case ' + primaryCase.Id + ' to Party ' + dnoPartyId);
            }

        } catch (Exception e) {
            Logger.error('Error setting DNO on Case: ' + e.getMessage());
            Logger.setScenario('InboundForm_S37Handler.setDNOOnCase');
            Logger.saveLog();
            System.debug(LoggingLevel.ERROR, 
                'Error setting DNO on Case: ' + e.getMessage());
        }
    }
    
    // ========================================================================
    // Populate Payment Lookup on Case PROCESSING
    // ========================================================================
    
    /**
     * Set the Payment__c field on Case__c to the Payment__c sObject record
     */
    private void setPaymentOnCase(Case__c primaryCase, Map<String, List<SObject>> insertedRecords) {
        if (!insertedRecords.containsKey('Payment__c')) {
            return;
        }
        
        Id paymentId = null;
        for (SObject record : insertedRecords.get('Payment__c')) {
            Payment__c payment = (Payment__c) record;
            if (payment.Id != null) {
                paymentId = payment.Id;
                break;
            }
        }
        
        if (paymentId == null) {
            System.debug(LoggingLevel.DEBUG, 'No Payment founnd to set Payment__c on Case');
            return;
        }
        
        // Update the Case with the Payment Id
        try {
            primaryCase.Payment__c = paymentId;
            System.debug(LoggingLevel.INFO, 'Set Payment__c on Case ' + primaryCase.Id + ' to Payment ' + paymentId);
        } catch (Exception e) {
            Logger.error('Error setting Payment on Case: ' + e.getMessage());
            Logger.setScenario('InboundForm_S37Handler.setPaymentOnCase');
            Logger.saveLog();
            System.debug(LoggingLevel.ERROR, 'Error setting Payment__c on Case: ' + e.getMessage());
        }
    }

    // ========================================================================
    // Populate Post_Consultation__c Lookup on Case PROCESSING
    // ========================================================================
    
    /**
     * Set the Post_Consultation__c field on Case__c to the Post_Consultation__c sObject record
     */
    private void setPostConsultationsCase(Case__c primaryCase, Map<String, List<SObject>> insertedRecords) {
        if (!insertedRecords.containsKey('Post_Consultation__c')) {
            return;
        }
        
        Id postConsultationId = null;
        for (SObject record : insertedRecords.get('Post_Consultation__c')) {
            Post_Consultation__c postConsultation = (Post_Consultation__c) record;
            if (postConsultation.Id != null) {
                postConsultationId = postConsultation.Id;
                break;
            }
        }
        
        if (postConsultationId == null) {
            System.debug(LoggingLevel.DEBUG, 'No Post Consultation founnd to set Post_Consultation__c on Case');
            return;
        }
        
        // Update the Case with the Post_Consultation__c Id
        try {
                primaryCase.Post_Consultation__c = postConsultationId;
                System.debug(LoggingLevel.INFO, 'Set Post_Consultation__c on Case ' + primaryCase.Id + ' to Post Consultation ' + postConsultationId);
        } catch (Exception e) {
            Logger.error('Error setting Post Consultation on Case: ' + e.getMessage());
            Logger.setScenario('InboundForm_S37Handler.setPostConsultationsCase');
            Logger.saveLog();
            System.debug(LoggingLevel.ERROR, 'Error setting Post_Consultation__c on Case: ' + e.getMessage());
        }
    }
}