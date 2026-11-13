import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const LAND_FIELDS = [
    { name: 'land-identification', label: 'Land Identification', field: 'Land_Identification__c' },
    { name: 'land-location', label: 'Land Location', field: 'Land_Location__c' },
    { name: 'land-registered', label: 'Registered with Land Registry?', field: 'Land_Registered_with_Land_Registry__c' },
    { name: 'land-registry-reference', label: 'Land Registry Reference Number', field: 'Land_Registry_Reference_Number__c' },
    { name: 'land-site-address', label: 'Site Address', field: 'Site_Address__c' },
    { name: 'land-not-registered-explanation', label: 'Explanation - Land not Registered', field: 'Explanation_Land_not_Registered__c' },
    { name: 'land-easting', label: 'Easting', field: 'Easting__c' },
    { name: 'land-northing', label: 'Northing', field: 'Northing__c' },
    { name: 'land-visible-from-road', label: 'Equipment Visible from Public Road', field: 'Equipment_Visible_from_Public_Road__c' },
    { name: 'land-other-identification', label: 'Other Info To Identify Land', field: 'Other_Info_To_Identify_Land__c' }
];

const OPTIONAL_LAND_FIELDS = LAND_FIELDS.map(({ field }) => `Land__c.${field}`);

export default class NwlLandDetails extends LightningElement {
    @api recordId;

    relatedLandId;
    caseLandRegistered;
    landRecord;
    isOpen = true;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: ['Case__c.Related_Land__c'],
        optionalFields: ['Case__c.Land__c']
    })
    wiredCase({ data }) {
        this.relatedLandId = data?.fields?.Related_Land__c?.value;
        this.caseLandRegistered = data?.fields?.Land__c;
    }

    @wire(getRecord, {
        recordId: '$relatedLandId',
        fields: ['Land__c.Name'],
        optionalFields: OPTIONAL_LAND_FIELDS
    })
    wiredLand({ data }) {
        this.landRecord = data;
    }

    get fields() {
        return [
            {
                key: 'land-registered-on-case',
                label: 'Land Registered with Land Registry?',
                value: this.caseLandRegistered?.displayValue
                    ?? this.caseLandRegistered?.value
                    ?? ''
            },
            ...LAND_FIELDS.map(({ name, label, field }) => ({
                key: name,
                label,
                value: this.landRecord?.fields?.[field]?.displayValue
                    ?? this.landRecord?.fields?.[field]?.value
                    ?? ''
            }))
        ];
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