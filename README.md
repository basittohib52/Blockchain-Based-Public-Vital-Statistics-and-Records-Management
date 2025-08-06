# Blockchain-Based Public Vital Statistics and Records Management

A comprehensive system for managing vital records on the blockchain, ensuring security, immutability, and controlled access to sensitive personal documents.

## System Overview

This system consists of five interconnected smart contracts that handle different aspects of vital records management:

### 1. Birth Registry Contract (`birth-registry.clar`)
- Issues and maintains secure birth certificates
- Tracks birth registrations with immutable records
- Provides certificate verification capabilities
- Manages parental information and birth details

### 2. Marriage & Divorce Records Contract (`marriage-divorce.clar`)
- Processes and maintains marriage licenses
- Records divorce decrees and legal separations
- Tracks relationship status changes
- Maintains historical relationship records

### 3. Adoption Records Contract (`adoption-records.clar`)
- Maintains confidential adoption records
- Facilitates authorized access to adoption information
- Protects privacy while enabling legitimate access
- Tracks adoption proceedings and finalization

### 4. Name Change Processing Contract (`name-change.clar`)
- Handles legal name changes
- Updates official documents across the system
- Maintains name change history
- Provides verification of legal name changes

### 5. Genealogy Research Contract (`genealogy-research.clar`)
- Helps individuals access historical vital records
- Facilitates family research with privacy controls
- Provides search capabilities across historical records
- Manages research permissions and access rights

## Key Features

### Security & Privacy
- Role-based access control for sensitive records
- Encryption of confidential information
- Audit trails for all record access
- Privacy protection for adoption and sensitive records

### Immutability & Verification
- Blockchain-based immutable record storage
- Cryptographic verification of document authenticity
- Tamper-proof record keeping
- Historical record preservation

### Access Control
- Multi-level authorization system
- Government official access controls
- Individual access to personal records
- Researcher access with proper permissions

## Data Structures

### Birth Records
- Personal identification information
- Birth location and date
- Parental information
- Medical information (if applicable)
- Certificate issuance details

### Marriage/Divorce Records
- Spouse information
- Marriage date and location
- Divorce details and dates
- Legal status tracking
- Certificate information

### Adoption Records
- Adoptee information
- Adoptive parent details
- Birth parent information (confidential)
- Court proceedings information
- Access authorization records

### Name Change Records
- Previous and new names
- Legal proceeding information
- Court order details
- Effective dates
- Cross-reference updates

## Installation & Setup

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to verify contracts
4. Deploy contracts using `clarinet deploy`
5. Run tests with `npm test`

## Usage

### For Government Officials
- Register births, marriages, divorces
- Process name changes
- Manage adoption proceedings
- Issue official certificates

### For Citizens
- Access personal vital records
- Request certified copies
- Update personal information
- Track document status

### For Researchers
- Access historical records (with permissions)
- Conduct genealogical research
- Verify family relationships
- Access public record information

## Testing

The system includes comprehensive tests using Vitest:
- Unit tests for each contract function
- Integration tests for cross-contract interactions
- Security tests for access controls
- Performance tests for large datasets

Run tests with:
\`\`\`bash
npm test
\`\`\`

## Security Considerations

- All sensitive data is encrypted before storage
- Access controls prevent unauthorized record access
- Audit logs track all system interactions
- Regular security audits recommended
- Backup and recovery procedures in place

## Compliance

This system is designed to comply with:
- HIPAA privacy requirements
- State vital records regulations
- Federal record-keeping standards
- International privacy laws (GDPR compliance ready)

## Contributing

Please read the PR-DETAILS.md file for contribution guidelines and development standards.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
