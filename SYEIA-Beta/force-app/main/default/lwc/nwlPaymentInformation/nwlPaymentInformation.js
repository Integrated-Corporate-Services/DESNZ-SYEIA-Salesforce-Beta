import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldDisplayValue, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import CASE_PAYMENT_FIELD from '@salesforce/schema/Case__c.Payment__c';
import CASE_FEE_PAID_FIELD from '@salesforce/schema/Case__c.Application_Fee_Paid__c';
import CASE_FEE_DATE_FIELD from '@salesforce/schema/Case__c.Date_of_Fee_Paid__c';
import CASE_PAYMENT_METHOD_FIELD from '@salesforce/schema/Case__c.Payment_Method__c';
import PAYMENT_DATE_FIELD from '@salesforce/schema/Payment__c.Payment_Date__c';
import PAYMENT_METHOD_FIELD from '@salesforce/schema/Payment__c.Payment_Method__c';
import PAYMENT_STATUS_FIELD from '@salesforce/schema/Payment__c.Status__c';
import PAYMENT_INVOICE_DATE_FIELD from '@salesforce/schema/Payment__c.Invoice_Date__c';
import PAYMENT_TOTAL_AMOUNT_FIELD from '@salesforce/schema/Payment__c.Total_Amount__c';

const PAYMENT_FIELDS = [
    PAYMENT_DATE_FIELD,
    PAYMENT_METHOD_FIELD,
    PAYMENT_STATUS_FIELD,
    PAYMENT_INVOICE_DATE_FIELD,
    PAYMENT_TOTAL_AMOUNT_FIELD
];

const CASE_FIELDS = [
    CASE_PAYMENT_FIELD,
    CASE_FEE_PAID_FIELD,
    CASE_FEE_DATE_FIELD,
    CASE_PAYMENT_METHOD_FIELD
];

const CASE_FIELD_DETAILS = [
    // { name: 'payment-method', label: 'Payment Type', field: CASE_PAYMENT_METHOD_FIELD }
];

const PAYMENT_FIELD_DETAILS = [
    { name: 'payment-date', label: 'Payment Date', field: PAYMENT_DATE_FIELD },
    { name: 'payment-method', label: 'Payment Method', field: PAYMENT_METHOD_FIELD },
    { name: 'payment-status', label: 'Status', field: PAYMENT_STATUS_FIELD },
    { name: 'invoice-date', label: 'Invoice Date', field: PAYMENT_INVOICE_DATE_FIELD },
    { name: 'total-amount', label: 'Total Amount', field: PAYMENT_TOTAL_AMOUNT_FIELD }
];

export default class NwlPaymentInformation extends LightningElement {
    @api recordId;

    pageRecordId;
    caseRecord;
    paymentId;
    paymentRecord;
    error;
    isLoaded = false;
    isOpen = true;

    @wire(CurrentPageReference)
    setPageReference(pageReference) {
        this.pageReference = pageReference;
    }

    get effectiveRecordId() {
        return this.pageReference?.state?.c__recordId;
    }

    @wire(getRecord, { recordId: '$effectiveRecordId', fields: CASE_FIELDS })
    wiredCase({ data, error }) {
        if (data) {
            this.caseRecord = data;
            this.paymentId = getFieldValue(data, CASE_PAYMENT_FIELD);
            this.paymentRecord = undefined;
            this.isLoaded = true;
        } else if (error) {
            this.caseRecord = undefined;
            this.paymentId = undefined;
            this.paymentRecord = undefined;
            this.isLoaded = true;
        }
    }

    @wire(getRecord, { recordId: '$paymentId', fields: PAYMENT_FIELDS })
    wiredPayment({ data }) {
        this.paymentRecord = data;
    }

    get hasRecordId() {
        return Boolean(this.effectiveRecordId);
    }

    get showContent() {
        return this.isLoaded;
    }

    get caseDetails() {
        return this.getFieldDetails(this.caseRecord, CASE_FIELD_DETAILS);
    }

    get paymentDetails() {
        return this.getFieldDetails(this.paymentRecord, PAYMENT_FIELD_DETAILS);
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