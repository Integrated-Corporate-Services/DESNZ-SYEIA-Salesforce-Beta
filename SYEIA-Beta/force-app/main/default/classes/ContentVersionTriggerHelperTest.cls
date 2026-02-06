/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ContentVersionTriggerHelperTest {

    @isTest
    static void blocksExeUpload() {
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.exe',
            VersionData = Blob.valueOf('Test content')
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(cv, false);
        Test.stopTest();

        // Assert that the insert failed due to blocked file extension
        // Assert.NotEquals(null, sr, 'Expected SaveResult to be returned');
        // Assert.equals(1, sr.getErrors().size(), 'Expected one error due to blocked file extension');
        // Assert.equals('Files with .exe extension are not allowed.', sr.getErrors()[0].getMessage(), 'Expected error message for blocked file extension');
        System.assert(!sr.isSuccess(), 'Expected insert to fail due to blocked file extension');
        System.assertEquals('Files with .exe extension are not allowed.', sr.getErrors()[0].getMessage(), 'Expected error message for blocked file extension');
    }

    @isTest static void allowsValidUpload() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.pdf',
            VersionData = Blob.valueOf('Test content')
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(cv, false);
        Test.stopTest();

        // Assert that the insert succeeded for allowed file extension
        System.assert(sr.isSuccess(), 'Expected insert to succeed for allowed file extension');
    }
}