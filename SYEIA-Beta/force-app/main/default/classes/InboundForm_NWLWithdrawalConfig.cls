/**
 * NWL withdrawal request configuration.
 */
public class InboundForm_NWLWithdrawalConfig {
    public static InboundForm_MappingConfig.FormTypeConfig getConfig() {
        return new InboundForm_MappingConfig.FormTypeConfig()
            .setFormType('NWL_WITHDRAWAL_REQUEST')
            .setDescription('Necessary Wayleaves withdrawal request event')
            .setPrimaryObject('Withdrawal_Request__c')
            .setInboundRequestLookupField(null)
            .setNameField(null)
            .setStatusField('Status__c')
            .setDefaultStatus('Pending')
            .setHandlerClass(InboundForm_NWLWithdrawalHandler.class)
            .addFieldMapping(InboundForm_MappingConfig.stringField(
                'Withdraw.withdrawalReason',
                'Withdrawal_Request_Reason__c'
            ));
    }
}