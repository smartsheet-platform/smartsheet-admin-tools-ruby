Smartsheet Bulk User Remove Utility
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

This command-line utility enables administrators of Team and Enterprise accounts to programmatically remove users from their org via the Smartsheet API.

Please note that as a result user logins are NOT deleted, but instead users are removed from the Smartsheet account, i.e. they cease to be members of the account and become free collaborators.  Users retain read-only access to their sheets, unless sheets are optionally transferred to another user (see options below).

Revision History
--------

* 1.0 - February 13, 2014 - Initial build


Dependencies
---

* Tested with Ruby 1.9.3 only.
* Ruby gems: httparty, activesupport, json. 
* Smartsheet Team or Enterprise plan.
* Smartsheet API access token that belongs to an account administrator.


Configuration
------

###User input list

Provide a CSV formatted list of users to be removed from your Smartsheet account.  Use the included user-list.csv sample file to get started.  The following columns
are expected, in this order:

* userID (required, you can get fetch these via /users call)
* userDescriptor (arbitrary value to help you identify the user being removed during execution or in the log output)
* transferTo (ID of user to transfer sheets to, empty otherwise)
* removeFromSharing (true if you want the user removed from sharing, empty otherwise)

See Smartsheet Help Center article on managing users
[managing users](http://help.smartsheet.com/customer/portal/articles/795920-managing-users) for more information.



###Config variables

In bulk-user-remove.rb, set the following config variables:

* SS_TOKEN - Smartsheet API access token that belongs to an account administrator.  See the [Smartsheet API docs](http://smartsheet.com/developers) for help on how to generate acess tokens.

* CSV_FILE - name of the file containing the list of users to be created.



Usage
---

###WARNING!
Exercise care when removing users from organizations, especially when choosing to transfer their sheets to others or removing them from sharing.

###Rate limit
Rate limit: The Smartsheet API enforces a rate limit of 300 calls per minute per access token (we reserve the right to change this rate, so please check the Smartsheet API docs to confirm).  The script is designed to gracefully handle the rate limit and will
sleep for 60 seconds before retrying whenever a rate limit error is encountered.

###Errors
If a non-fatal error is encountered, the utility will print a meaningful error message, skip the current user, and will continue to execute through the rest of the user list. 

###Logging
Verbose status messages and errors are printed to output.  It is strongly recommended that you redirect your output to a log file in case you need to troubleshoot your batch.
