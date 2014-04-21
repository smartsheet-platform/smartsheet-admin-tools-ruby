Smartsheet Bulk Email Contact Update Utility
===

License and Warranty
--------------------
Copyright 2014 Smartsheet.com

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


Overview
--------

This command-line utility enables administrators of Smartsheet accounts to programmatically update email addresses in CONTACT_LIST columns via the Smartsheet API.


Revision History
--------
* 1.0 - April 21, 2014 - Initial build


Dependencies
---

* Tested with Ruby 1.9.3 only.
* Ruby gems: httparty, activesupport, json. 
* Smartsheet API access token that belongs to an account administrator.


Configuration
------

###Email map

Provide a CSV formatted map of old email addresses to new email address.  Use the included email-map.csv sample file to get started.  The following columns
are expected, in this order:

* Old email address (required)
* New email address (required)


###Config variables

In bulk-email-contact-update.rb, set the following config variables:

* SS_TOKEN - Smartsheet API access token that belongs to an account administrator.  See the [Smartsheet API docs](http://smartsheet.com/developers) for help on how to generate acess tokens.

* CSV_FILE - name of the file containing the list of users to be created.


Usage
---

###Rate limit
Rate limit: The Smartsheet API enforces a rate limit of 300 calls per minute per access token (we reserve the right to change this rate, so please check the Smartsheet API docs to confirm).  The script is designed to gracefully handle the rate limit and will
sleep for 60 seconds before retrying whenever a rate limit error is encountered.

###Logging
Verbose status messages and errors are printed to output.  It is strongly recommended that you redirect your output to a log file in case you need to troubleshoot your batch.
