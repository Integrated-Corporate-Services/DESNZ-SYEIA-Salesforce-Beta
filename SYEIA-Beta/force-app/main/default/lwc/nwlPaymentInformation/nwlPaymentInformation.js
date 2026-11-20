import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldDisplayValue, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import CASE_PAYMENT_FIELD from '@salesforce/schema/Case__c.Payment__c';
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

const CASE_FIELDS = [CASE_PAYMENT_FIELD];

const CASE_FIELD_DETAILS = [
    { name: 'payment-method', label: 'Payment Type', field: CASE_PAYMENT_METHOD_FIELD }
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

    pageReference;
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
            console.log('Case data received:', data);
            const paymentId = getFieldValue(data, CASE_PAYMENT_FIELD) || undefined;
            if (paymentId !== this.paymentId) {
                this.paymentRecord = undefined;
                this.error = undefined;
                this.paymentId = paymentId;
                console.log('Payment ID changed:', paymentId);
            }
            if (!paymentId) {
                this.error = undefined;
            }
            this.isLoaded = !paymentId || Boolean(this.paymentRecord) || Boolean(this.error);
        } 
        else if (error) {
            this.caseRecord = undefined;
            this.paymentId = undefined;
            this.paymentRecord = undefined;
            // this.error = 'Unable to load the case payment information.';
            console.error(this.error, error);
            this.isLoaded = true;
        }
    }

    @wire(getRecord, { recordId: '$paymentId', fields: PAYMENT_FIELDS })
    wiredPayment({ data, error }) {
        if (data) {
            console.log('Payment data received:', data);
            this.paymentRecord = data;
            this.error = undefined;
            this.isLoaded = true;
        } else if (error) {
            this.paymentRecord = undefined;
            this.error = 'Unable to load the linked payment.';
            console.error(this.error, error);
            this.isLoaded = true;
        }
    }

    get hasRecordId() {
        return Boolean(this.effectiveRecordId);
    }

    get showContent() {
        return this.isLoaded && !this.error;
    }

    get hasNoPayment() {
        return this.isLoaded && !this.error && !this.paymentId;
    }

    get caseDetails() {
        return this.getFieldDetails(this.caseRecord, CASE_FIELD_DETAILS);
    }

    get paymentDetails() {
        console.log('Payment record:', this.paymentRecord);
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