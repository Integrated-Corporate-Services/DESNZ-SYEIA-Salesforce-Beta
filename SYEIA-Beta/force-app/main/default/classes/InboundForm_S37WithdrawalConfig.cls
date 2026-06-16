/**
 * S37 withdrawal request configuration.
 */
public class InboundForm_S37WithdrawalConfig {
    public static InboundForm_MappingConfig.FormTypeConfig getConfig() {
        return new InboundForm_MappingConfig.FormTypeConfig()
            .setFormType('S37_WITHDRAWAL_REQUEST')
            .setDescription('Section 37 withdrawal request event')
            .setPrimaryObject('Withdrawal_Request__c')
            .setInboundRequestLookupField(null)
            .setNameField(null)
            .setStatusField('Status__c')
            .setDefaultStatus('Pending')
            .setHandlerClass(InboundForm_S37WithdrawalHandler.class)
            .addFieldMapping(InboundForm_MappingConfig.stringField(
                'Withdraw.withdrawalReason',
                'Withdrawal_Request_Reason__c'
            ));
    }
}
