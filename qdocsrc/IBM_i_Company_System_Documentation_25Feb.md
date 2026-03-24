# IBM i Company System - Technical Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Module Descriptions](#module-descriptions)
4. [Data Flow Diagrams](#data-flow-diagrams)
5. [Program Call Sequences](#program-call-sequences)
6. [Database Schema](#database-schema)
7. [Build Configuration](#build-configuration)
8. [Include Files](#include-files)

---

## System Overview

The IBM i Company System is a multi-tier application for managing departments and employees. It provides interactive screens for viewing departments, browsing employees by department, and adding new employees.

### Key Features
- Department listing with subfile display
- Employee browsing by department
- New employee creation with validation
- Service program for data retrieval
- SQL-based data access layer

### Technology Stack
- **Language**: RPG IV (ILE RPG) - Free-form
- **Database**: Db2 for IBM i
- **UI**: Display Files (DSPF) with Subfiles
- **Architecture**: Modular with service programs

---

## Architecture

### System Architecture Diagram

```mermaid
flowchart TB
    subgraph "Presentation Layer"
        DEPTS[depts.pgm.sqlrpgle<br/>Department List]
        EMPS[employees.pgm.sqlrpgle<br/>Employee List]
        NEWEMP[newemp.pgm.sqlrpgle<br/>New Employee]
    end
    
    subgraph "Business Logic Layer"
        EMPDET[empdet.sqlrpgle<br/>Service Program]
    end
    
    subgraph "Data Layer"
        DB[(Db2 for IBM i<br/>DEPARTMENT<br/>EMPLOYEE)]
    end
    
    subgraph "UI Layer"
        DEPTSDSPF[depts.dspf]
        EMPSDSPF[emps.dspf]
        NEWEMPDSPF[nemp.dspf]
    end
    
    DEPTS -->|Displays| DEPTSDSPF
    EMPS -->|Displays| EMPSDSPF
    NEWEMP -->|Displays| NEWEMPDSPF
    
    DEPTS -->|Calls| EMPS
    DEPTS -->|Calls| NEWEMP
    EMPS -->|Uses| EMPDET
    
    DEPTS -->|SQL Query| DB
    EMPS -->|SQL Query| DB
    NEWEMP -->|SQL Insert| DB
    EMPDET -->|SQL Query| DB
    
    style EMPDET fill:#e1f5ff
    style DB fill:#ffe1e1
```

### Component Relationships

```mermaid
graph LR
    subgraph "Programs"
        A[depts.pgm]
        B[employees.pgm]
        C[newemp.pgm]
        D[mypgm.pgm]
    end
    
    subgraph "Service Programs"
        E[empdet.srvpgm]
    end
    
    subgraph "Binding"
        F[app.bnddir]
    end
    
    subgraph "Include Files"
        G[constants.rpgleinc]
        H[empdet.rpgleinc]
    end
    
    A -.includes.-> G
    B -.includes.-> G
    B -.includes.-> H
    C -.includes.-> G
    D -.includes.-> G
    
    B -->|binds to| F
    F -->|references| E
    E -.defines.-> H
    
    style E fill:#d4edda
    style F fill:#fff3cd
```

---

## Module Descriptions

### 1. depts.pgm.sqlrpgle - Department List Program

**Purpose**: Main entry point displaying all departments in a subfile with options to view employees or add new employees.

**Control Specifications**:
- `DFTACTGRP(*NO)`: Program runs in a named activation group (not default)

**Key Components**:

```mermaid
flowchart TD
    START([Program Start]) --> INIT[Initialize Variables<br/>Exit = *Off]
    INIT --> LOAD[LoadSubfile]
    LOAD --> LOOP{Exit?}
    LOOP -->|No| DISPLAY[Display Footer<br/>Exfmt SFLCTL]
    DISPLAY --> CHECK{Function Key?}
    CHECK -->|F03| SETEXIT[Exit = *On]
    CHECK -->|ENTER| HANDLE[HandleInputs]
    SETEXIT --> LOOP
    HANDLE --> LOOP
    LOOP -->|Yes| END([*INLR = *ON<br/>Return])
    
    style START fill:#90EE90
    style END fill:#FFB6C1
```

**File Specifications**:
- Display file: `depts` (WORKSTN)
- Subfile: `SFLDta` with RRN control
- Indicator DS: `WkStnInd` for screen control
- File Info DS: `fileinfo` for function key detection

**Data Structures**:
- `Department`: Externally described from DEPARTMENT table with alias names
- `WkStnInd`: Maps indicators to positions for subfile control

**Procedures**:

1. **ClearSubfile()**
   - Turns off subfile display and control indicators
   - Writes SFLCTL record to clear buffer
   - Resets RRN (Relative Record Number) to 0

2. **LoadSubfile()**
   ```mermaid
   flowchart LR
       A[Clear Subfile] --> B[Declare Cursor<br/>deptCur]
       B --> C[Open Cursor]
       C --> D{SQL OK?}
       D -->|Yes| E[Fetch Loop]
       E --> F{More Records?}
       F -->|Yes| G[Fetch Department]
       G --> H[Populate Subfile<br/>XID, XNAME]
       H --> I[Write SFLDTA<br/>rrn += 1]
       I --> F
       F -->|No| J[Close Cursor]
       D -->|No| J
       J --> K{rrn > 0?}
       K -->|Yes| L[SflDsp = *On<br/>SFLRRN = 1]
       K -->|No| M[End]
       L --> M
   ```

3. **HandleInputs()**
   - Reads changed subfile records (ReadC)
   - Processes user selections:
     - Option '5': Call `Employees()` program
     - Option '8': Call `NewEmp()` program
   - Clears selection field after processing

**SQL Operations**:
```sql
DECLARE deptCur CURSOR FOR
  SELECT DEPTNO, DEPTNAME
  FROM DEPARTMENT
```

---

### 2. employees.pgm.sqlrpgle - Employee List Program

**Purpose**: Displays employees for a specific department with total salaries.

**Control Specifications**:
- `DFTACTGRP(*NO)`: Named activation group
- `BNDDIR('APP')`: Uses APP binding directory for service program access

**Parameters**:
- `DEPTNO` (Char(3)): Department number passed from calling program

**Key Components**:

```mermaid
flowchart TD
    START([Program Entry<br/>DEPTNO parameter]) --> INIT[Initialize<br/>Exit = *Off]
    INIT --> LOADSFL[LoadSubfile]
    LOADSFL --> GETDEPT[getDeptDetail<br/>DEPTNO]
    GETDEPT --> CHECK{Found?}
    CHECK -->|No| RETURN1([Return])
    CHECK -->|Yes| SETTOT[XTOT = totalsalaries]
    SETTOT --> LOOP{Exit?}
    LOOP -->|No| DISPLAY[Write Footer<br/>Exfmt SFLCTL]
    DISPLAY --> FKEY{Function Key?}
    FKEY -->|F12| SETEXIT[Exit = *On]
    FKEY -->|ENTER| HANDLE[HandleInputs]
    SETEXIT --> LOOP
    HANDLE --> LOOP
    LOOP -->|Yes| RETURN2([*INLR = *ON<br/>Return])
    
    style START fill:#90EE90
    style RETURN1 fill:#FFB6C1
    style RETURN2 fill:#FFB6C1
```

**File Specifications**:
- Display file: `emps` (WORKSTN)
- Subfile: `SFLDta` with RRN control

**Procedures**:

1. **LoadSubfile()**
   ```sql
   DECLARE empCur CURSOR FOR
     SELECT EMPNO, FIRSTNME, LASTNAME, JOB
     FROM EMPLOYEE
     WHERE WORKDEPT = :DEPTNO
   ```
   - Fetches all employees for the specified department
   - Formats name as "LASTNAME, FIRSTNAME"
   - Populates subfile with employee data

2. **HandleInputs()**
   - Processes option '5': Display employee ID (DSPLY XID)
   - Clears selection after processing

**External Dependencies**:
- Service Program: `EMPDET` (via APP binding directory)
- Procedure: `getDeptDetail()`

---

### 3. newemp.pgm.sqlrpgle - New Employee Program

**Purpose**: Interactive screen for adding new employees with validation.

**Control Specifications**:
- `DFTACTGRP(*NO)`: Named activation group

**Parameters**:
- `currentDepartment` (Char(3)): Department for new employee

**Program Flow**:

```mermaid
flowchart TD
    START([Program Entry<br/>currentDepartment]) --> GENID[getNewEmpId]
    GENID --> CHECKID{ID Generated?}
    CHECKID -->|No| SETERR1[XERR = Error Message]
    CHECKID -->|Yes| SETID[XID = autoEmpId]
    SETERR1 --> SETDEPT
    SETID --> SETDEPT[XDEPT = currentDepartment]
    SETDEPT --> LOOP{Exit?}
    LOOP -->|No| DISPLAY[Write Header<br/>Exfmt DETAIL]
    DISPLAY --> VALIDATE[GetError]
    VALIDATE --> F12{F12 Pressed?}
    F12 -->|Yes| SETEXIT[Exit = *On]
    F12 -->|No| CHECKERR{Error Empty?}
    CHECKERR -->|Yes| INSERT[HandleInsert]
    CHECKERR -->|No| SHOWERR[XERR = currentError]
    INSERT --> SUCCESS{Insert OK?}
    SUCCESS -->|Yes| SETEXIT2[Exit = *On]
    SUCCESS -->|No| INSERR[XERR = Error Message]
    SETEXIT --> LOOP
    SETEXIT2 --> LOOP
    SHOWERR --> LOOP
    INSERR --> LOOP
    LOOP -->|Yes| END([Return])
    
    style START fill:#90EE90
    style END fill:#FFB6C1
```

**Procedures**:

1. **HandleInsert()**
   - Creates new employee data structure
   - Populates fields from screen input
   - Sets default values for unused fields
   - Executes SQL INSERT with NC (no commit)
   ```sql
   INSERT INTO EMPLOYEE
   VALUES (:newEmp)
   WITH NC
   ```

2. **GetError()**
   - Validates all required fields:
     - First name, middle initial, last name
     - Department, job title
     - Salary (must be numeric)
     - Phone number (must be numeric)
   - Returns error message or empty string

3. **getNewEmpId()**
   ```mermaid
   flowchart LR
       A[Initialize<br/>result = '000000'] --> B[SQL: SELECT MAX<br/>INT EMPNO]
       B --> C{SQL OK?}
       C -->|Yes| D[highestEmpId + 100]
       D --> E[Convert to Char]
       E --> F[Right-align in result]
       F --> G[Return result]
       C -->|No| H[Return empty string]
       
       style G fill:#90EE90
       style H fill:#FFB6C1
   ```
   - Generates next employee ID by finding max and adding 100
   - Returns 6-character zero-padded ID

---

### 4. empdet.sqlrpgle - Employee Detail Service Program

**Purpose**: Reusable service program providing data retrieval procedures.

**Control Options**:
- `NOMAIN`: No main procedure (service program only)

**Exported Procedures**:

#### getEmployeeDetail()

```mermaid
flowchart TD
    START([Input: empno]) --> INIT[Initialize<br/>employee_detail DS]
    INIT --> SQL[SQL SELECT:<br/>Name Concatenation<br/>Total Income]
    SQL --> CHECK{SQLCODE = 0?}
    CHECK -->|Yes| FOUND[employee_detail.found = *ON]
    CHECK -->|No| NOTFOUND[employee_detail.found = *OFF]
    FOUND --> RETURN([Return employee_detail])
    NOTFOUND --> RETURN
    
    style START fill:#90EE90
    style RETURN fill:#FFB6C1
```

**SQL Query**:
```sql
SELECT
  RTRIM(FIRSTNME) || ' ' || RTRIM(MIDINIT) || ' ' || RTRIM(LASTNAME),
  SALARY + BONUS + COMM
INTO
  :employee_detail.name,
  :employee_detail.netincome
FROM
  EMPLOYEE
WHERE
  EMPNO = :empno
```

**Returns**: `employee_detail_t` structure with:
- `found`: Indicator if employee exists
- `name`: Full formatted name
- `netincome`: Total compensation

#### getDeptDetail()

```mermaid
flowchart TD
    START([Input: deptno]) --> INIT[Initialize<br/>department_detail DS]
    INIT --> SQL[SQL SELECT:<br/>Department Info<br/>+ Subquery for Total Salaries]
    SQL --> CHECK{SQLCODE = 0?}
    CHECK -->|Yes| FOUND[department_detail.found = *ON]
    CHECK -->|No| NOTFOUND[department_detail.found = *OFF]
    FOUND --> RETURN([Return department_detail])
    NOTFOUND --> RETURN
    
    style START fill:#90EE90
    style RETURN fill:#FFB6C1
```

**SQL Query**:
```sql
SELECT
  RTRIM(DEPTNAME),
  COALESCE(LOCATION, 'N/A'),
  (SELECT SUM(SALARY + BONUS + COMM)
   FROM EMPLOYEE
   WHERE WORKDEPT = :deptno)
INTO
  :department_detail.deptname,
  :department_detail.location,
  :department_detail.totalsalaries
FROM
  DEPARTMENT
WHERE
  DEPTNO = :deptno
```

**Returns**: `department_detail_t` structure with:
- `found`: Indicator if department exists
- `deptname`: Department name
- `location`: Department location (or 'N/A')
- `totalsalaries`: Sum of all employee compensation

---

### 5. mypgm.pgm.rpgle - Simple Test Program

**Purpose**: Demonstration program showing external C function call.

**Control Specifications**:
- `DFTACTGRP(*NO)`: Named activation group

**Key Features**:
- Calls C `printf()` function via external procedure
- Uses `DSPLY` operation for display
- Simple "Hello World" style program

**Code Flow**:
```mermaid
flowchart LR
    A[Start] --> B[mytext = 'Hello to all you people']
    B --> C[printf mytext]
    C --> D[dsply mytext]
    D --> E[return]
    
    style A fill:#90EE90
    style E fill:#FFB6C1
```

---

## Data Flow Diagrams

### Department to Employee Navigation Flow

```mermaid
sequenceDiagram
    actor User
    participant DEPTS as depts.pgm
    participant DEPTDB as DEPARTMENT Table
    participant EMPS as employees.pgm
    participant EMPDET as empdet.srvpgm
    participant DEPTDB2 as DEPARTMENT Table
    participant EMPDB as EMPLOYEE Table
    
    User->>DEPTS: Start Application
    DEPTS->>DEPTDB: SELECT DEPTNO, DEPTNAME
    DEPTDB-->>DEPTS: Department List
    DEPTS->>User: Display Subfile
    
    User->>DEPTS: Select Option 5 (View Employees)
    DEPTS->>EMPS: CALL Employees(DEPTNO)
    
    EMPS->>EMPDET: getDeptDetail(DEPTNO)
    EMPDET->>DEPTDB2: SELECT with Salary Subquery
    DEPTDB2-->>EMPDET: Department Details + Total Salaries
    EMPDET-->>EMPS: department_detail_t
    
    EMPS->>EMPDB: SELECT EMPNO, FIRSTNME, LASTNAME, JOB<br/>WHERE WORKDEPT = :DEPTNO
    EMPDB-->>EMPS: Employee List
    EMPS->>User: Display Employee Subfile
    
    User->>EMPS: Press F12
    EMPS-->>DEPTS: Return
    DEPTS->>User: Display Department Subfile
```

### New Employee Creation Flow

```mermaid
sequenceDiagram
    actor User
    participant DEPTS as depts.pgm
    participant NEWEMP as newemp.pgm
    participant EMPDB as EMPLOYEE Table
    
    User->>DEPTS: Select Option 8 (New Employee)
    DEPTS->>NEWEMP: CALL NewEmp(DEPTNO)
    
    NEWEMP->>EMPDB: SELECT MAX(INT(EMPNO))
    EMPDB-->>NEWEMP: Highest Employee ID
    NEWEMP->>NEWEMP: Generate New ID (max + 100)
    
    NEWEMP->>User: Display Entry Screen<br/>(Pre-filled: ID, Department)
    
    loop Until Valid or F12
        User->>NEWEMP: Enter Employee Data
        NEWEMP->>NEWEMP: GetError() - Validate Fields
        
        alt Validation Failed
            NEWEMP->>User: Display Error Message
        else Validation Passed
            NEWEMP->>EMPDB: INSERT INTO EMPLOYEE
            alt Insert Successful
                EMPDB-->>NEWEMP: Success
                NEWEMP-->>DEPTS: Return
            else Insert Failed
                EMPDB-->>NEWEMP: Error
                NEWEMP->>User: Display Error
            end
        end
    end
    
    User->>NEWEMP: Press F12 (Cancel)
    NEWEMP-->>DEPTS: Return
```

### Service Program Data Retrieval

```mermaid
flowchart TB
    subgraph "Calling Programs"
        A[employees.pgm]
    end
    
    subgraph "Service Program - empdet.srvpgm"
        B[getDeptDetail]
        C[getEmployeeDetail]
    end
    
    subgraph "Database"
        D[(DEPARTMENT)]
        E[(EMPLOYEE)]
    end
    
    A -->|Call with DEPTNO| B
    B -->|Query Department| D
    B -->|Subquery: SUM Salaries| E
    B -->|Return department_detail_t| A
    
    C -->|Query Employee| E
    C -->|Return employee_detail_t| A
    
    style B fill:#e1f5ff
    style C fill:#e1f5ff
```

---

## Program Call Sequences

### Complete Application Flow

```mermaid
sequenceDiagram
    actor User
    participant DEPTS as depts.pgm.sqlrpgle
    participant EMPS as employees.pgm.sqlrpgle
    participant NEWEMP as newemp.pgm.sqlrpgle
    participant EMPDET as empdet.sqlrpgle
    participant DB as Database
    
    Note over User,DB: Application Startup
    User->>DEPTS: Start
    DEPTS->>DB: Load Departments
    DB-->>DEPTS: Department List
    DEPTS->>User: Display Subfile
    
    Note over User,DB: View Employees Scenario
    User->>DEPTS: Option 5 on Department
    DEPTS->>EMPS: Call with DEPTNO
    EMPS->>EMPDET: getDeptDetail(DEPTNO)
    EMPDET->>DB: Query Department + Salaries
    DB-->>EMPDET: Department Details
    EMPDET-->>EMPS: Return Structure
    EMPS->>DB: Load Employees for Dept
    DB-->>EMPS: Employee List
    EMPS->>User: Display Employee Subfile
    User->>EMPS: F12 (Return)
    EMPS-->>DEPTS: Return Control
    
    Note over User,DB: Add Employee Scenario
    User->>DEPTS: Option 8 on Department
    DEPTS->>NEWEMP: Call with DEPTNO
    NEWEMP->>DB: Get Max Employee ID
    DB-->>NEWEMP: Max ID
    NEWEMP->>User: Display Entry Form
    User->>NEWEMP: Enter Data + Enter
    NEWEMP->>NEWEMP: Validate Input
    NEWEMP->>DB: Insert Employee
    DB-->>NEWEMP: Success/Failure
    NEWEMP-->>DEPTS: Return Control
    
    Note over User,DB: Exit Application
    User->>DEPTS: F03 (Exit)
    DEPTS->>User: End Program
```

---

## Database Schema

### Entity Relationship Diagram

```mermaid
erDiagram
    DEPARTMENT ||--o{ EMPLOYEE : "has"
    
    DEPARTMENT {
        char3 DEPTNO PK "Department Number"
        varchar50 DEPTNAME "Department Name"
        varchar50 LOCATION "Location"
    }
    
    EMPLOYEE {
        char6 EMPNO PK "Employee Number"
        varchar30 FIRSTNME "First Name"
        char1 MIDINIT "Middle Initial"
        varchar30 LASTNAME "Last Name"
        char3 WORKDEPT FK "Work Department"
        varchar20 JOB "Job Title"
        date HIREDATE "Hire Date"
        date BIRTHDATE "Birth Date"
        smallint EDLEVEL "Education Level"
        decimal9_2 SALARY "Salary"
        decimal9_2 BONUS "Bonus"
        decimal9_2 COMM "Commission"
        varchar10 PHONENO "Phone Number"
    }
```

### Table Descriptions

#### DEPARTMENT Table
- **Primary Key**: DEPTNO
- **Purpose**: Stores department information
- **Used By**: 
  - `depts.pgm.sqlrpgle` - List all departments
  - `empdet.sqlrpgle` - Get department details

#### EMPLOYEE Table
- **Primary Key**: EMPNO
- **Foreign Key**: WORKDEPT → DEPARTMENT.DEPTNO
- **Purpose**: Stores employee information
- **Used By**:
  - `employees.pgm.sqlrpgle` - List employees by department
  - `newemp.pgm.sqlrpgle` - Insert new employees
  - `empdet.sqlrpgle` - Get employee details

---

## Build Configuration

### Binding Directory Structure

```mermaid
flowchart TD
    A[app.bnddir] -->|Contains| B[EMPDET *SRVPGM]
    C[employees.pgm] -->|Uses| A
    D[empdet.sqlrpgle] -->|Compiled to| B
    E[empdet.bnd] -->|Exports| F[GETEMPLOYEEDETAIL]
    E -->|Exports| G[GETDEPTDETAIL]
    D -->|Uses| E
    
    style A fill:#fff3cd
    style B fill:#d4edda
    style E fill:#f8d7da
```

### Build Process

**app.bnddir** - Binding Directory Creation:
```cl
/* Delete existing binding directory */
DLTOBJ OBJ(&O/&N) OBJTYPE(*BNDDIR)

/* Create new binding directory */
CRTBNDDIR BNDDIR(&O/&N)

/* Add service program entry */
ADDBNDDIRE BNDDIR(&O/&N) OBJ((*LIBL/EMPDET *SRVPGM))
```

**empdet.bnd** - Service Program Exports:
```
STRPGMEXP  PGMLVL(*CURRENT) SIGNATURE('V1')
  EXPORT SYMBOL('GETEMPLOYEEDETAIL')
  EXPORT SYMBOL('GETDEPTDETAIL')
ENDPGMEXP
```

---

## Include Files

### constants.rpgleinc - Function Key Constants

**Purpose**: Defines hexadecimal constants for function keys and special keys.

**Constants Defined**:
- F01 through F24: Function keys
- ENTER: Enter key
- HELP: Help key
- PRINT: Print key

**Usage**: Included in all interactive programs for function key detection.

**Example**:
```rpgle
Dcl-C F03 X'33';  // Function key 3
Dcl-C F12 X'3C';  // Function key 12
Dcl-C ENTER X'F1'; // Enter key
```

### empdet.rpgleinc - Service Program Interface

**Purpose**: Defines data structures and prototypes for the empdet service program.

**Data Structures**:

1. **employee_detail_t** (Template)
   - `found` (Ind): Indicator if employee was found
   - `name` (Varchar(50)): Full formatted employee name
   - `netincome` (Packed(9:2)): Total compensation

2. **department_detail_t** (Template)
   - `found` (Ind): Indicator if department was found
   - `deptname` (Varchar(50)): Department name
   - `location` (Varchar(50)): Department location
   - `totalsalaries` (Packed(9:2)): Sum of all employee salaries

**Prototypes**:

1. **getDeptDetail()**
   - Parameter: `deptno` (Char(3) const)
   - Returns: `department_detail_t` structure
   - External Procedure: 'GETDEPTDETAIL'

2. **getEmployeeDetail()**
   - Parameter: `empno` (Char(6) const)
   - Returns: `employee_detail_t` structure
   - External Procedure: 'GETEMPLOYEEDETAIL'

---

## Summary

This IBM i Company System demonstrates modern RPG development practices:

1. **Modular Design**: Separation of concerns with service programs
2. **SQL Integration**: Embedded SQL for database operations
3. **Reusable Components**: Include files for constants and interfaces
4. **Interactive UI**: Subfile-based screens for data display
5. **Data Validation**: Input validation before database operations
6. **Error Handling**: SQL state checking and user feedback

The application follows a three-tier architecture with clear separation between presentation (display files), business logic (service programs), and data access (SQL queries).