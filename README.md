# **Clarity Medical Records**  
*A Decentralized Medical Database Management System*

## **Overview**  
The Clarity Medical Records smart contract provides a decentralized, secure, and permissioned system for managing medical records. Built using Clarity, this contract ensures data privacy, controlled access, and integrity while enabling healthcare providers to manage patient files efficiently.

## **Features**  
✅ **Secure File Storage** – Store medical records with structured metadata.  
✅ **Access Control** – Manage viewing rights for patients and providers.  
✅ **Auditability** – Maintain integrity with transparent, on-chain transactions.  
✅ **Privacy Enforcement** – Restrict unauthorized access to sensitive data.  
✅ **Provider Transfers** – Allow ownership transfers between healthcare providers.  
✅ **Customizable Categories** – Classify files with metadata for efficient indexing.  

## **Smart Contract Structure**  

### **1. Data Structures**
- **`health-files`**: Stores medical file metadata.
- **`viewing-rights`**: Manages access permissions for files.
- **`records-count`**: Tracks the number of registered files.

### **2. System Response Codes**
- `u301` – File Not Found  
- `u302` – Duplicate File  
- `u303` – Invalid Identifier  
- `u304` – Invalid Content Volume  
- `u305` – Authentication Failure  
- `u308` – Unauthorized Access Attempt  

### **3. Core Functions**

#### **File Management**
- **`create-file(subject-identifier, content-volume, clinical-summary, categories)`**  
  Creates a new medical record with structured metadata.  
- **`modify-file(file-id, new-subject-identifier, new-volume, new-summary, new-categories)`**  
  Updates an existing file with new details.  
- **`remove-file(file-id)`**  
  Deletes a medical file from the system.  

#### **Access Control**
- **`authorize-access(file-id, viewer-principal)`**  
  Grants viewing permission to a specific user.  
- **`verify-access(file-id, viewer-principal)`**  
  Checks if a user has access to a medical file.  

#### **Information Retrieval**
- **`get-file-details(file-id)`**  
  Fetches all metadata for a given file.  
- **`get-system-stats()`**  
  Retrieves the total number of stored files.  
- **`get-file-provider(file-id)`**  
  Returns the healthcare provider associated with a file.  
- **`get-file-timestamp(file-id)`**  
  Fetches the block height when the file was recorded.  

## **Installation & Deployment**  

### **Prerequisites**  
- Clarity Language SDK  
- Stacks Blockchain Network  

### **Deploying the Contract**  
1. Clone the repository:  
   ```sh
   git clone https://github.com/yourusername/clarity-medical-records.git
   cd clarity-medical-records
   ```
2. Deploy using the Clarity CLI:  
   ```sh
   clarity-cli check clarity-medical-records.clar
   clarity-cli launch clarity-medical-records.clar
   ```
3. Interact via the Stacks blockchain interface.

## **Usage Examples**  

### **Creating a Medical File**
```clarity
(create-file "patient123" u5000 "Routine check-up notes" ["general", "lab-results"])
```

### **Granting Access**
```clarity
(authorize-access u1 'SP12345XYZ)
```

### **Retrieving a File**
```clarity
(get-file-details u1)
```

## **Security Considerations**  
- **Restricted Access:** Only authorized providers can modify records.  
- **Immutable Audit Trail:** Transactions are permanently stored on the blockchain.  
- **Admin Controls:** The system administrator can enforce access policies.  

## **License**  
This project is licensed under the MIT License.

