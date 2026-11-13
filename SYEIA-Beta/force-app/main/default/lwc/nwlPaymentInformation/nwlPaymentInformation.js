import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldDisplayValue, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import CASE_PAYMENT_FIELD from '@salesforce/schema/Case__c.Payment__c';
import CASE_FEE_PAID_FIELD from '@salesforce/schema/Case__c.Application_Fee_Paid__c';
import CASE_FEE_DATE_FIELD from '@salesforce/schema/Case__c.Date_of_Fee_Paid__c';
import CASE_PAYMENT_METHOD_FIELD from '@salesforce/schema/Case__c.Payment_Method__c';
import PAYMENT_ID_FIELD from '@salesforce/schema/Payment__c.Payment_Id__c';
import PAYMENT_DATE_FIELD from '@salesforce/schema/Payment__c.Payment_Date__c';
import PAYMENT_METHOD_FIELD from '@salesforce/schema/Payment__c.Payment_Method__c';
import PAYMENT_STATUS_FIELD from '@salesforce/schema/Payment__c.Status__c';
import PAYMENT_INVOICE_REFERENCE_FIELD from '@salesforce/schema/Payment__c.Invoice_Reference__c';
import PAYMENT_INVOICE_DATE_FIELD from '@salesforce/schema/Payment__c.Invoice_Date__c';
import PAYMENT_DESCRIPTION_FIELD from '@salesforce/schema/Payment__c.Description__c';
import PAYMENT_ITEM_REFERENCE_FIELD from '@salesforce/schema/Payment__c.Item_Reference__c';
import PAYMENT_QUANTITY_FIELD from '@salesforce/schema/Payment__c.Quantity__c';
import PAYMENT_SUBTOTAL_FIELD from '@salesforce/schema/Payment__c.Subtotal__c';
import PAYMENT_TOTAL_AMOUNT_FIELD from '@salesforce/schema/Payment__c.Total_Amount__c';

const PAYMENT_FIELDS = [
    PAYMENT_ID_FIELD,
    PAYMENT_DATE_FIELD,
    PAYMENT_METHOD_FIELD,
    PAYMENT_STATUS_FIELD,
    PAYMENT_INVOICE_REFERENCE_FIELD,
    PAYMENT_INVOICE_DATE_FIELD,
    PAYMENT_DESCRIPTION_FIELD,
    PAYMENT_ITEM_REFERENCE_FIELD,
    PAYMENT_QUANTITY_FIELD,
    PAYMENT_SUBTOTAL_FIELD,
    PAYMENT_TOTAL_AMOUNT_FIELD
];

const CASE_FIELDS = [
    CASE_PAYMENT_FIELD,
    CASE_FEE_PAID_FIELD,
    CASE_FEE_DATE_FIELD,
    CASE_PAYMENT_METHOD_FIELD
];

const CASE_FIELD_DETAILS = [
    { name: 'fee-paid', label: 'Application Fee Paid?', field: CASE_FEE_PAID_FIELD },
    { name: 'fee-date', label: 'Date of Fee Paid', field: CASE_FEE_DATE_FIELD },
    { name: 'payment-method', label: 'Payment Type', field: CASE_PAYMENT_METHOD_FIELD }
];

const PAYMENT_FIELD_DETAILS = [
    { name: 'payment-id', label: 'Payment Id', field: PAYMENT_ID_FIELD },
    { name: 'payment-date', label: 'Payment Date', field: PAYMENT_DATE_FIELD },
    { name: 'payment-method', label: 'Payment Method', field: PAYMENT_METHOD_FIELD },
    { name: 'payment-status', label: 'Status', field: PAYMENT_STATUS_FIELD },
    { name: 'invoice-reference', label: 'Invoice Reference', field: PAYMENT_INVOICE_REFERENCE_FIELD },
    { name: 'invoice-date', label: 'Invoice Date', field: PAYMENT_INVOICE_DATE_FIELD },
    { name: 'description', label: 'Item Description', field: PAYMENT_DESCRIPTION_FIELD },
    { name: 'item-reference', label: 'Item Reference', field: PAYMENT_ITEM_REFERENCE_FIELD },
    { name: 'quantity', label: 'Quantity', field: PAYMENT_QUANTITY_FIELD },
    { name: 'subtotal', label: 'Subtotal', field: PAYMENT_SUBTOTAL_FIELD },
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
        this.pageRecordId =
            pageReference?.state?.c__recordId || pageReference?.attributes?.recordId;
    }

    get effectiveRecordId() {
        return this.recordId || this.pageRecordId;
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