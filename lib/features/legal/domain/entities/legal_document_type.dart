/// Which legal document to fetch. Each maps to its own public endpoint
/// (`terms-and-conditions` / `privacy-policy`); both share one wire shape.
/// Order matches the P/T-2 segmented toggle: الشروط (terms) then الخصوصية.
enum LegalDocumentType { termsAndConditions, privacyPolicy }
