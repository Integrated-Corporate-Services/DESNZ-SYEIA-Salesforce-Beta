import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldDisplayValue, getFieldValue } from 'lightning/uiRecordApi';
import OBJECTOR_FIELD from '@salesforce/schema/Case__c.Objector__c';
import LANDOWNER_FIELD from '@salesforce/schema/Case__c.Landowner__c';
import RELATED_LAND_FIELD from '@salesforce/schema/Case__c.Related_Land__c';
import IS_OBJECTOR_LANDOWNER_FIELD from '@salesforce/schema/Case__c.Is_Objector_also_Landowner__c';
import OBJECTOR_REPRESENTATIVE_FIELD from '@salesforce/schema/Case__c.Does_Objector_Have_Representative__c';
import CASE_LAND_REGISTERED_FIELD from '@salesforce/schema/Case__c.Land__c';
import CASE_OBJECT from '@salesforce/schema/Case__c';
import PARTY_OBJECT from '@salesforce/schema/Party__c';
import LAND_OBJECT from '@salesforce/schema/Land__c';
import PARTY_NAME_FIELD from '@salesforce/schema/Party__c.Name';
import PARTY_SALUTATION_FIELD from '@salesforce/schema/Party__c.Salutation__c';
import PARTY_FIRST_NAME_FIELD from '@salesforce/schema/Party__c.First_Name__c';
import PARTY_LAST_NAME_FIELD from '@salesforce/schema/Party__c.Last_Name__c';
import PARTY_ORGANISATION_FIELD from '@salesforce/schema/Party__c.Organisation__c';
import PARTY_TYPE_FIELD from '@salesforce/schema/Party__c.Party_Type__c';
import PARTY_EMAIL_FIELD from '@salesforce/schema/Party__c.Email__c';
import PARTY_PHONE_FIELD from '@salesforce/schema/Party__c.Phone__c';
import LAND_IDENTIFICATION_FIELD from '@salesforce/schema/Land__c.Land_Identification__c';
import LAND_LOCATION_FIELD from '@salesforce/schema/Land__c.Land_Location__c';
import LAND_REGISTERED_FIELD from '@salesforce/schema/Land__c.Land_Registered_with_Land_Registry__c';
import LAND_REGISTRY_REFERENCE_FIELD from '@salesforce/schema/Land__c.Land_Registry_Reference_Number__c';
import LAND_SITE_ADDRESS_FIELD from '@salesforce/schema/Land__c.Site_Address__c';
import LAND_NOT_REGISTERED_EXPLANATION_FIELD from '@salesforce/schema/Land__c.Explanation_Land_not_Registered__c';
import LAND_EASTING_FIELD from '@salesforce/schema/Land__c.Easting__c';
import LAND_NORTHING_FIELD from '@salesforce/schema/Land__c.Northing__c';
import LAND_EQUIPMENT_VISIBLE_FIELD from '@salesforce/schema/Land__c.Equipment_Visible_from_Public_Road__c';
import LAND_OTHER_IDENTIFICATION_FIELD from '@salesforce/schema/Land__c.Other_Info_To_Identify_Land__c';

const CASE_FIELDS = [
    OBJECTOR_FIELD,
    LANDOWNER_FIELD,
    RELATED_LAND_FIELD,
    IS_OBJECTOR_LANDOWNER_FIELD,
    OBJECTOR_REPRESENTATIVE_FIELD,
    CASE_LAND_REGISTERED_FIELD
];

const PARTY_FIELDS = [
    PARTY_NAME_FIELD,
    PARTY_SALUTATION_FIELD,
    PARTY_FIRST_NAME_FIELD,
    PARTY_LAST_NAME_FIELD,
    PARTY_ORGANISATION_FIELD,
    PARTY_TYPE_FIELD,
    PARTY_EMAIL_FIELD,
    PARTY_PHONE_FIELD
];

const LAND_FIELDS = [
    LAND_IDENTIFICATION_FIELD,
    LAND_LOCATION_FIELD,
    LAND_REGISTERED_FIELD,
    LAND_REGISTRY_REFERENCE_FIELD,
    LAND_SITE_ADDRESS_FIELD,
    LAND_NOT_REGISTERED_EXPLANATION_FIELD,
    LAND_EASTING_FIELD,
    LAND_NORTHING_FIELD,
    LAND_EQUIPMENT_VISIBLE_FIELD,
    LAND_OTHER_IDENTIFICATION_FIELD
];

const CASE_OBJECTOR_DETAILS = [
    { name: 'objector-is-landowner', label: 'Is Objector also Landowner?', field: IS_OBJECTOR_LANDOWNER_FIELD },
    { name: 'objector-has-representative', label: 'Does Objector Have Representative?', field: OBJECTOR_REPRESENTATIVE_FIELD }
];

const PARTY_DETAILS = [
    { name: 'party-name', label: 'Name', field: PARTY_NAME_FIELD },
    { name: 'party-salutation', label: 'Salutation', field: PARTY_SALUTATION_FIELD },
    { name: 'party-first-name', label: 'First Name', field: PARTY_FIRST_NAME_FIELD },
    { name: 'party-last-name', label: 'Last Name', field: PARTY_LAST_NAME_FIELD },
    { name: 'party-organisation', label: 'Organisation', field: PARTY_ORGANISATION_FIELD },
    { name: 'party-type', label: 'Party Type', field: PARTY_TYPE_FIELD },
    { name: 'party-email', label: 'Email', field: PARTY_EMAIL_FIELD },
    { name: 'party-phone', label: 'Phone', field: PARTY_PHONE_FIELD }
];

const CASE_LAND_DETAILS = [
    { name: 'land-registered-on-case', label: 'Land Registered with Land Registry?', field: CASE_LAND_REGISTERED_FIELD }
];

const LAND_DETAILS = [
    { name: 'land-identification', label: 'Land Identification', field: LAND_IDENTIFICATION_FIELD },
    { name: 'land-location', label: 'Land Location', field: LAND_LOCATION_FIELD },
    { name: 'land-registered', label: 'Registered with Land Registry?', field: LAND_REGISTERED_FIELD },
    { name: 'land-registry-reference', label: 'Land Registry Reference Number', field: LAND_REGISTRY_REFERENCE_FIELD },
    { name: 'land-site-address', label: 'Site Address', field: LAND_SITE_ADDRESS_FIELD },
    { name: 'land-not-registered-explanation', label: 'Explanation - Land not Registered', field: LAND_NOT_REGISTERED_EXPLANATION_FIELD },
    { name: 'land-easting', label: 'Easting', field: LAND_EASTING_FIELD },
    { name: 'land-northing', label: 'Northing', field: LAND_NORTHING_FIELD },
    { name: 'land-visible-from-road', label: 'Equipment Visible from Public Road', field: LAND_EQUIPMENT_VISIBLE_FIELD },
    { name: 'land-other-identification', label: 'Other Info To Identify Land', field: LAND_OTHER_IDENTIFICATION_FIELD }
];

export default class NwlObjectorLandDetails extends LightningElement {
    @api recordId;

    objectorId;
    landownerId;
    relatedLandId;
    caseRecord;
    objectorRecord;
    landownerRecord;
    landRecord;
    isLoaded = false;
    isObjectorOpen = true;
    isLandOpen = true;

    caseObject = CASE_OBJECT.objectApiName;
    partyObject = PARTY_OBJECT.objectApiName;
    landObject = LAND_OBJECT.objectApiName;
    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    wiredCase({ data, error }) {
        if (data) {
            this.caseRecord = data;
            this.objectorId = getFieldValue(data, OBJECTOR_FIELD);
            this.landownerId = getFieldValue(data, LANDOWNER_FIELD);
            this.relatedLandId = getFieldValue(data, RELATED_LAND_FIELD);
            this.isLoaded = true;
        } else if (error) {
            this.caseRecord = undefined;
            this.objectorId = undefined;
            this.landownerId = undefined;
            this.relatedLandId = undefined;
            this.isLoaded = true;
        }
    }

    @wire(getRecord, { recordId: '$objectorId', fields: PARTY_FIELDS })
    wiredObjector({ data }) {
        this.objectorRecord = data;
    }

    @wire(getRecord, { recordId: '$landownerId', fields: PARTY_FIELDS })
    wiredLandowner({ data }) {
        this.landownerRecord = data;
    }

    @wire(getRecord, { recordId: '$relatedLandId', fields: LAND_FIELDS })
    wiredLand({ data }) {
        this.landRecord = data;
    }

    get hasRecordId() {
        return Boolean(this.recordId);
    }

    get caseObjectorDetails() {
        return this.getFieldDetails(this.caseRecord, CASE_OBJECTOR_DETAILS);
    }

    get objectorDetails() {
        return this.getFieldDetails(this.objectorRecord, PARTY_DETAILS);
    }

    get landownerDetails() {
        return this.getFieldDetails(this.landownerRecord, PARTY_DETAILS);
    }

    get caseLandDetails() {
        return this.getFieldDetails(this.caseRecord, CASE_LAND_DETAILS);
    }

    get landDetails() {
        return this.getFieldDetails(this.landRecord, LAND_DETAILS);
    }

    get objectorSectionClass() {
        return this.isObjectorOpen ? 'slds-section slds-is-open' : 'slds-section';
    }

    get objectorIconName() {
        return this.isObjectorOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get landSectionClass() {
        return this.isLandOpen ? 'slds-section slds-is-open' : 'slds-section';
    }

    get landIconName() {
        return this.isLandOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    toggleSection(event) {
        if (event.currentTarget.dataset.section === 'objector') {
            this.isObjectorOpen = !this.isObjectorOpen;
        } else {
            this.isLandOpen = !this.isLandOpen;
        }
    }

    getFieldDetails(record, fields) {
        return fields.map(({ name, label, field }) => ({
            key: name,
            label,
            value: record
                ? getFieldDisplayValue(record, field) ?? getFieldValue(record, field) ?? ''
                : ''
        }));
    }
}