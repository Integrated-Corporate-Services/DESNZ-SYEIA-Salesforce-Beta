import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const PARTY_FIELDS = [
    { name: 'name', label: 'Landowner', field: 'Name' },
    { name: 'salutation', label: 'Salutation', field: 'Salutation__c' },
    { name: 'first-name', label: 'First Name', field: 'First_Name__c' },
    { name: 'last-name', label: 'Last Name', field: 'Last_Name__c' },
    { name: 'organisation', label: 'Organisation', field: 'Organisation__c' },
    { name: 'party-type', label: 'Party Type', field: 'Party_Type__c' },
    { name: 'email', label: 'Email', field: 'Email__c' },
    { name: 'phone', label: 'Phone', field: 'Phone__c' }
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

export default class NwlLandownerDetails extends LightningElement {
    @api recordId;

    landownerId;
    landownerRecord;
    isOpen = true;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: ['Case__c.Landowner__c']
    })
    wiredCase({ data }) {
        this.landownerId = data?.fields?.Landowner__c?.value;
    }

    @wire(getRecord, {
        recordId: '$landownerId',
        fields: ['Party__c.Name'],
        optionalFields: OPTIONAL_PARTY_FIELDS
    })
    wiredLandowner({ data }) {
        this.landownerRecord = data;
    }

    get fields() {
        return PARTY_FIELDS.map(({ name, label, field }) => ({
            key: name,
            label,
            value: this.landownerRecord?.fields?.[field]?.displayValue
                ?? this.landownerRecord?.fields?.[field]?.value
                ?? ''
        }));
    }

    get sectionClass() {
        return this.isOpen ? 'slds-section slds-is-open' : 'slds-section';
    }

    get iconName() {
        return this.isOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    toggleSection() {
        this.isOpen = !this.isOpen;
    }
}