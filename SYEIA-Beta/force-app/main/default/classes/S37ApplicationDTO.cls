public class S37ApplicationDTO {
    public S37ApplicationDTO() {}

    public String formType;
    public Metadata metadata;
    public String applicationId;
    public Sections sections;

    public class Metadata {
        public String source;
        public Integer schemaVersion;
    }

    public class Sections {
        public Location location;
        public List<Object> parishes;
        public WorksOverview worksOverview;
        public SensitiveAreaChecks sensitiveAreaChecks;
        public SensitiveAreaReview sensitiveAreaReview;
        public ProjectDetails projectDetails;
        public List<AssetInformation> assetInformation;
        public NetworkOperator networkOperator;
        public List<ApplicationParty> application_party;
        public SupportingInformation supportingInformation;
        public EiaFees eiaFees;
    }

    // --- Location ---
    public class Location {
        public List<Route> routes;
    }

    public class Route {
        public String route_id;
        public String routeName;
        public List<GridPoint> gridPoints;
        public String disconnectedroute_justification;
    }

    public class GridPoint {
        public String point_id;
        public Integer easting;
        public Integer northing;
    }

    // --- Works Overview ---
    public class WorksOverview {
        public String createdBy;
        public String lastUpdatedBy;
        public String applicationId;
        public Integer polesAdded;
        public Integer polesReplaced;
        public Integer poleMaterial;
        public String poleComments;
        public String vehiclesRequired;
        public Integer estimatedDuration;
        public Boolean excavationRequired;
        public String excavationDetails;
        public Integer chemicalTreatments;
        public String removalDescription;
        public String accessRoutesDetails;
        public Boolean roadClosuresRequired;
        public Boolean addingOrReplacingLines;
        public Boolean addingOrReplacingPoles;
        public String overheadLineDescription;
        public Boolean removingExistingEquipment;
        public Boolean usingExistingAccessRoutes;
        public Boolean vegetationClearanceRequired;
        public String vegetationClearanceDetails;
        public String generalComments;
    }

    // --- Sensitive Areas ---
    public class SensitiveAreaChecks {
        public String application_id;
        public List<String> layers;
    }

    public class SensitiveAreaReview {
        public String id;
        public String route_id;
        public String created_at;
        public String updated_at;
        public String reviewed_at;
        public String reviewed_by;
        public String settings_id;
        public Integer asset_presence_option_id;
        public String other_sensitive_areas_note;
    }

    // --- Project Details ---
    public class ProjectDetails {
        public Overview overview;
    }

    public class Overview {
        public ProjectDetailsInner project_details;
        public ApplicationProjectOverview application_project_overview;
        public List<PlanDocument> planDocuments;
        public List<ApplicationRelation> application_relations;
    }

    public class ProjectDetailsInner {
        public String project_id;
        public String project_name;
        public String project_description;
        public String created_at;
        public String created_by;
        public String updated_at;
    }

    public class ApplicationProjectOverview {
        public String plan_reference;
        public Double max_structure_height_m;
        public Integer earliest_work_start_date_year;
        public Integer earliest_work_start_date_month;
        public Integer latest_work_start_date_year;
        public Integer latest_work_start_date_month;
    }

    public class PlanDocument {
        public String title;
        public String description;
        public String file_id;
        public String document_id;
        public String virtual_folder;
        public String added_at;
        public String added_by;
        public String category;
        public String subcategory;
    }

    public class ApplicationRelation {
        public String application_relation_id;
        public String project_name;
        public String relation_type;
        public String related_application_id;
        public String details;
        public String created_at;
    }

    // --- Asset Information ---
    public class AssetInformation {
        public String asset_id;
        public String asset_type;
        public String tori_noi;
        public String asset_reference;
        public String description;
        public Boolean is_existing;
        public String created_at;
        public String created_by;
        public String last_updated_at;
        public String last_updated_by;
    }

    // --- Network Operator ---
    public class NetworkOperator {
        public Details details;
    }

    public class Details {
        public String operator_ref;
        public String created_at;
        public String created_by;
        public String submitted_at;
    }

    // --- Application Party ---
    public class ApplicationParty {
        public String application_party_id;
        public String role;
        public Boolean is_primary;
        public String person_id;
        public String person_name;
        public String email;
        public String phone;
        public String line1;
        public String line2;
        public String town_city;
        public String country;
        public String postcode;
        public String contact_id;
        public Boolean contact_isconfirmed;
        public String organisation_id;
        public String organisation_name;
        public String application_id;
    }

    // --- Supporting Information ---
    public class SupportingInformation {
        public List<SupportingDocument> supportingDocuments;
        public SupportingQuestions supportingQuestions;
    }

    public class SupportingDocument {
        // public String title;
        // public String file_id;
        // public String category;
        // public String virtual_folder;
        // public String description;
        // public String document_id;
        // public String added_at;
        // public String added_by;
        // public String subcategory;
    }

    public class SupportingQuestions {
        // public String id;
        // public Boolean wayleaves_obtained;
        // public String wayleaves_not_obtained_reason;
        // public Boolean esqcr_2002_compliance_confirmed;
        // public Boolean has_additional_supporting_documents;
        // public String applicant_supporting_comments;
        // public String applicationId;
    }

    // --- EIA Fees ---
    public class EiaFees {
        // public String eia_id;
        // public Boolean screening_only;
        // public Boolean requires_full_eia;
        // public Boolean is_eia_development;
        // public String created_at;
        // public String created_by;
        // public String updated_at;
        // public String updated_by;
    }

    public static S37ApplicationDTO parse(String json) {
        return (S37ApplicationDTO) System.JSON.deserialize(json, S37ApplicationDTO.class);
    }

}