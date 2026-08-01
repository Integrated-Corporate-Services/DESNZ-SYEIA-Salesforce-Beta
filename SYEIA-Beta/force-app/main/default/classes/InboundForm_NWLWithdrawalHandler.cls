public class InboundForm_NWLWithdrawalHandler implements InboundForm_Processor.IFormHandler {
    // Alias handler for semantic NWL withdrawal naming. Behavior intentionally delegated.
    private final InboundForm_S37WithdrawalHandler delegate = new InboundForm_S37WithdrawalHandler();

    public List<String> validate(InboundForm_JSONParser parser) {
        return delegate.validate(parser);
    }

    public void afterBuild(InboundForm_JSONParser parser, Map<String, List<SObject>> records) {
        delegate.afterBuild(parser, records);
    }

    public void afterPrimaryInsert(
        InboundForm_JSONParser parser,
        Id primaryRecordId,
        InboundForm_Processor.ProcessingResult result
    ) {
        delegate.afterPrimaryInsert(parser, primaryRecordId, result);
    }

    public void afterAllInserts(Id primaryRecordId, Map<String, List<SObject>> insertedRecords) {
        delegate.afterAllInserts(primaryRecordId, insertedRecords);
    }
}