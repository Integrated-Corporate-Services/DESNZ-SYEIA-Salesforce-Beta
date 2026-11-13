import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class CaseDetails extends LightningElement {
    @api recordId;
    @api area = 'A';

    pageRecordId;
    sections = [
        {
            area: 'A',
            name: 'event-details',
            label: 'Event Details',
            contentId: 'event-details-content',
            fields: [
                'Name',
                'PINS_PEDW_1st_Referral_Date__c',
                'PINS_PEDW_2nd_Referral_Date__c',
                'Inspector_s_Report_Received_Date__c',
                'PINS_PEDW_Comments__c',
                'Site_Visit_Date__c',
                'Oral_Hearing_Date__c',
                'Name_Of_Inspector__c'
            ],
            isOpen: true
        },
        {
            area: 'A',
            name: 'applicant-details',
            label: 'Applicant Details',
            contentId: 'applicant-details-content',
            fields: [
                'DNO_Name__c',
                'Applicant_Name_Formula__c',
                'Applicant_Reference__c'
            ],
            isOpen: true
        },
        {
            area: 'A',
            name: 'application-details',
            label: 'Application Details',
            contentId: 'application-details-content',
            fields: [
                'Application_Type__c',
                'Type_Of_NWL_That_Existed__c',
                'Notice_to_Remove_Date__c',
                'Legislation_Applicable__c',
                'Wayleave_Expiry_Date__c',
                'Notice_Clearly_Refers_to_Line_Removal__c',
                'Submitted_Within_3_Months_Of_Notice__c',
                'Standard_15_Year_Term__c'
            ],
            isOpen: true
        },
        {
            area: 'A',
            name: 'objector-details',
            label: 'Objector Details',
            childComponent: 'objector',
            isOpen: true
        },
        {
            area: 'A',
            name: 'land-details',
            label: 'Land Details',
            childComponent: 'land',
            isOpen: true
        },
        {
            area: 'A',
            name: 'assets',
            label: 'Assets',
            contentId: 'assets-content',
            fields: ['Assets_Match_Application_Plan__c'],
            isOpen: true
        },
        {
            area: 'A',
            name: 'negotiations',
            label: 'Negotiations',
            contentId: 'negotiations-content',
            fields: [
                'Negotiations_in_Progress__c',
                'Evidence_of_Negotiations__c',
                'Start_Date_of_Negotiations__c'
            ],
            isOpen: true
        },
        {
            area: 'A',
            name: 'additional-information',
            label: 'Additional Information',
            contentId: 'additional-information-content',
            fields: [
                'Related_Applications__c',
                'Description_of_Important_Information__c',
                'Any_Other_Important_Information__c'
            ],
            isOpen: true
        },
        {
            area: 'A',
            name: 'supporting-information',
            label: 'Supporting Information',
            contentId: 'supporting-information-content',
            fields: [
                'Current_Landowner_Signed_Wayleave__c',
                'Wayleave_Payments_Previously_to_Grantor__c',
                'Is_a_New_Contract_Implied__c',
                'Written_Termination_Notice_Been_Given__c',
                'Written_Removal_Notice_Been_Given__c',
                'Does_Application_Include_a_Title_Plan__c',
                'Landowner_Inherited_a_Necessary__c',
                'Wayleave_Payments_Accepted_by_Grantor__c',
                'Written_Termination_Notice_Issue_Date__c',
                'Written_Removal_Notice_Issue_Date__c'
            ],
            isOpen: true
        },
        {
            area: 'B',
            name: 'case-overview',
            label: 'Case Overview',
            contentId: 'case-overview-content',
            fields: [
                'Status__c',
                'Sub_Status__c',
                'Application_Fee_Paid__c',
                'Date_of_Fee_Paid__c',
                'Payment_Method__c'
            ],
            isOpen: true
        },
        {
            area: 'B',
            name: 'assessment-details',
            label: 'Assessment Details',
            contentId: 'assessment-details-content',
            fields: [
                'Date_of_Application__c',
                'Assessment_Date__c',
                'Acknowledgement_Letter_Date__c',
                'Oral_Hearing_Requested_By_Either_Party__c',
                'CTWR_Letter_Date__c',
                'CTWR_Deadline__c',
                'CTWR_Response_From_Applicant_Date__c',
                'CTWR_Response_From_Landowner_Date__c'
            ],
            isOpen: true
        },
        {
            area: 'B',
            name: 'representation-details',
            label: 'Representation Details',
            contentId: 'representation-details-content',
            fields: [
                'Procedure__c',
                'Procedural_Notice_Letter_Date__c',
                'Statement_Of_Evidence_Exchange_Date__c',
                'Deadline_For_Further_Representations__c',
                'Further_Representations_Exchange_Letter__c',
                'Deadline_For_Statement_Of_Evidence__c',
                'Applicant_Statement_Date__c',
                'Landowner_Objector_Statement_Date__c',
                'Applicant_Further_Representations_Date__c',
                'Landowner_Further_Representations_Date__c'
            ],
            isOpen: true
        },
        {
            area: 'B',
            name: 'decision-details',
            label: 'Decision Details',
            contentId: 'decision-details-content',
            fields: [
                'Decision_Deadline_Formula__c',
                'Decision_Date__c',
                'Decision_Letter_Issued_in_Time_Formula__c',
                'Invalid_Letter_Date__c',
                'Withdrawn_Letter_Date__c',
                'DESNZ_Decision__c',
                'Agreed_With_Inspector_s_Recommendation__c',
                'Time_To_Decision_After_Inspector_Report__c',
                'Total_Time_Excluding_Abeyance_In_Days__c',
                'Total_Time_Including_Abeyance_In_Days__c'
            ],
            isOpen: true
        },
        {
            area: 'B',
            name: 'abeyance-details',
            label: 'Abeyance Details',
            contentId: 'abeyance-details-content',
            fields: [
                'X1st_Abeyance_Start_Date__c',
                'X1st_Abeyance_End_Date__c',
                'X1st_Abeyance_Duration_In_Days__c',
                'X2nd_Abeyance_Start_Date__c',
                'X2nd_Abeyance_End_Date__c',
                'X2nd_Abeyance_Duration_In_Days__c'
            ],
            isOpen: true
        }
    ].map((section) => ({
        ...section,
        hasFields: Boolean(section.fields?.length),
        sectionClass: 'slds-section slds-is-open',
        iconName: 'utility:chevrondown'
    }));

    @wire(CurrentPageReference)
    setPageReference(pageReference) {
        this.pageRecordId =
            pageReference?.state?.c__recordId || pageReference?.attributes?.recordId;
    }

    get effectiveRecordId() {
        return this.recordId || this.pageRecordId;
    }

    get visibleSections() {
        const selectedArea = this.area?.trim().toUpperCase();
        return this.sections
            .filter((section) => {
                if (section.area !== selectedArea) {
                    return false;
                }

                return true;
            })
            .map((section) => ({
                ...section,
                isChildComponent: Boolean(section.childComponent),
                isObjectorComponent: section.childComponent === 'objector',
                isLandComponent: section.childComponent === 'land'
            }));
    }

    toggleSection(event) {
        const sectionName = event.currentTarget.dataset.sectionName;
        this.sections = this.sections.map((section) => {
            if (section.name !== sectionName) {
                return section;
            }

            const isOpen = !section.isOpen;
            return {
                ...section,
                isOpen,
                sectionClass: isOpen ? 'slds-section slds-is-open' : 'slds-section',
                iconName: isOpen ? 'utility:chevrondown' : 'utility:chevronright'
            };
        });
    }
}