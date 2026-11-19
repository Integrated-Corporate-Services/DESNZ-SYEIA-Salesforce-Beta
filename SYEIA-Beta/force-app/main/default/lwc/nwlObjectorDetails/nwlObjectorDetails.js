import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const CASE_FIELDS = ['Case__c.Objector__c'];
const OPTIONAL_CASE_FIELDS = [
    'Case__c.Representative__c',
    'Case__c.Landowner__c',
    'Case__c.Is_Objector_also_Landowner__c',
    'Case__c.Does_Objector_Have_Representative__c'
];
const OPTIONAL_PARTY_FIELDS = [
    'Party__c.Salutation__c',
    'Party__c.First_Name__c',
    'Party__c.Last_Name__c',
    'Party__c.Organisation__c',
    'Party__c.Party_Type__c',
    'Party__c.Email__c',
    'Party__c.Phone__c'
];
const PARTY_FIELDS = [
    { name: 'name', label: 'Objector', field: 'Name' },
    { name: 'salutation', label: 'Salutation', field: 'Salutation__c' },
    { name: 'first-name', label: 'First Name', field: 'First_Name__c' },
    { name: 'last-name', label: 'Last Name', field: 'Last_Name__c' },
    { name: 'organisation', label: 'Organisation', field: 'Organisation__c' },
    { name: 'party-type', label: 'Party Type', field: 'Party_Type__c' },
    { name: 'email', label: 'Email', field: 'Email__c' },
    { name: 'phone', label: 'Phone', field: 'Phone__c' }
];
const REPRESENTATIVE_FIELDS = PARTY_FIELDS.map((item) => ({
    ...item,
    name: `representative-${item.name}`,
    label: item.field === 'Name' ? 'Representative' : item.label
}));
const LANDOWNER_FIELDS = PARTY_FIELDS.map((item) => ({
    ...item,
    name: `landowner-${item.name}`,
    label: item.field === 'Name' ? 'Landowner' : item.label
}));
const OBJECTOR_CASE_FIELDS = [
    { name: 'is-landowner', label: 'Is Objector also Landowner?', field: 'Is_Objector_also_Landowner__c' },
    { name: 'has-representative', label: 'Does Objector Have Representative?', field: 'Does_Objector_Have_Representative__c' }
];

export default class NwlObjectorDetails extends LightningElement {
    @api recordId;

    objectorId;
    representativeId;
    landownerId;
    hasRepresentative = false;
    hasLandowner = false;
    caseRecord;
    objectorRecord;
    representativeRecord;
    landownerRecord;
    objectorOpen = true;
    representativeOpen = true;
    landownerOpen = true;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: CASE_FIELDS,
        optionalFields: OPTIONAL_CASE_FIELDS
    })
    wiredCase({ data }) {
        this.caseRecord = data;
        this.objectorId = data?.fields?.Objector__c?.value;
        this.representativeId = data?.fields?.Representative__c?.value;
        this.landownerId = data?.fields?.Landowner__c?.value;
        this.hasRepresentative =
            data?.fields?.Does_Objector_Have_Representative__c?.value === 'Yes';
        this.hasLandowner =
            data?.fields?.Is_Objector_also_Landowner__c?.value === 'No';
    }

    @wire(getRecord, {
        recordId: '$objectorId',
        fields: ['Party__c.Name'],
        optionalFields: OPTIONAL_PARTY_FIELDS
    })
    wiredObjector({ data }) {
        this.objectorRecord = data;
    }

    @wire(getRecord, {
        recordId: '$representativeId',
        fields: ['Party__c.Name'],
        optionalFields: OPTIONAL_PARTY_FIELDS
    })
    wiredRepresentative({ data }) {
        this.representativeRecord = data;
    }

    @wire(getRecord, {
        recordId: '$landownerId',
        fields: ['Party__c.Name'],
        optionalFields: OPTIONAL_PARTY_FIELDS
    })
    wiredLandowner({ data }) {
        this.landownerRecord = data;
    }

    get objectorFields() {
        return this.mapFields(this.objectorRecord, PARTY_FIELDS);
    }

    get objectorCaseFields() {
        return this.mapFields(this.caseRecord, OBJECTOR_CASE_FIELDS);
    }

    get representativeFields() {
        return this.mapFields(this.representativeRecord, REPRESENTATIVE_FIELDS);
    }

    get landownerFields() {
        return this.mapFields(this.landownerRecord, LANDOWNER_FIELDS);
    }

    get objectorSectionClass() {
        return this.objectorOpen ? 'slds-section slds-is-open' : 'slds-section';
    }

    get objectorIconName() {
        return this.objectorOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get representativeSectionClass() {
        return this.representativeOpen ? 'slds-section slds-is-open' : 'slds-section';
    }

    get representativeIconName() {
        return this.representativeOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get landownerSectionClass() {
        return this.landownerOpen ? 'slds-section slds-is-open' : 'slds-section';
    }

    get landownerIconName() {
        return this.landownerOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    toggleSection(event) {
        if (event.currentTarget.dataset.section === 'objector') {
            this.objectorOpen = !this.objectorOpen;
        } else if (event.currentTarget.dataset.section === 'representative') {
            this.representativeOpen = !this.representativeOpen;
        } else {
            this.landownerOpen = !this.landownerOpen;
        }
    }

    mapFields(record, fields) {
        return fields.map(({ name, label, field }) => ({
            key: name,
            label,
            value: record?.fields?.[field]?.displayValue
                ?? record?.fields?.[field]?.value
                ?? ''
        }));
    }
}