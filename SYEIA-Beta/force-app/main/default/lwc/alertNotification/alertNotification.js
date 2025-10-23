import { LightningElement, api } from 'lwc';

export default class AlertNotification extends LightningElement {
    @api alertHeading = 'Alert Heading';
    @api alertMessage = '';
    @api alertTheme = 'info';
    @api showIcon = false;
    @api isDismissible = false;

    get alertClass() {
        return `slds-notify slds-notify_alert slds-theme_${this.alertTheme}`;
    }

    get iconName() {
        const iconMap = {
            info: 'utility:info',
            success: 'utility:success',
            warning: 'utility:warning',
            error: 'utility:error',
            offline: 'utility:offline'
        };
        return iconMap[this.alertTheme] || 'utility:info';
    }

    get iconVariant() {
        return this.alertTheme === 'warning' ? 'warning' : 'inverse';
    }

    get hasMessage() {
        return this.alertMessage && this.alertMessage.trim().length > 0;
    }

    handleClose() {
        const alertElement = this.template.querySelector('.slds-notify_alert');
        if (alertElement) {
            alertElement.classList.add('slds-hide');
        }
    }
}