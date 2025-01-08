table 50100 "Imported Excel Data"
{
    DataClassification = CustomerContent;
    
    fields
    {
        field(1; "Batch No."; Integer)
        {
            Caption = 'Batch No.';
        }
        field(2; "Item No."; Integer)
        {
            Caption = 'Item No.';
        }
        field(3; "Type"; Option)
        {
            Caption = 'Type';
            OptionMembers = "P","C";
            OptionCaption = 'Personal,Company';
        }
        field(4; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
        }
        field(5; "First Name"; Text[50])
        {
            Caption = 'First Name';
        }
        field(6; "Last Name"; Text[50])
        {
            Caption = 'Last Name';
        }
        field(7; "Passport No."; Text[30])
        {
            Caption = 'Passport No.';
        }
    }

    keys
    {
        key(PK; "Batch No.", "Item No.")
        {
            Clustered = true;
        }
    }
} 