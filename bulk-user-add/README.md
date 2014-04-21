Smartsheet Bulk User Add Utility
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

This command-line utility enables administrators of Team and Enterprise accounts to programmatically add users via the Smartsheet API.


Revision History
--------
* 1.2 - January 22, 2014 - Updated instructions
* 1.1 - January 16, 2014 - Improved logging and error handling
* 1.0 - June 16, 2013 - Initial build


Dependencies
---

* Tested with Ruby 1.9.3 only.
* Ruby gems: httparty, activesupport, json. 
* Smartsheet Team or Enterprise plan.
* Smartsheet API access token that belongs to an account administrator.


Configuration
------

###User input list

Provide a CSV formatted list of users to be added to your Smartsheet account.  Use the included user-list.csv sample file to get started.  The following columns
are expected, in this order:

* Email (required)
* FirstName (first name, empty otherwise)
* LastName (last name, empty otherwise)
* Admin ("yes" if admin, empty otherwise)
* Licensed ("yes" if licensed user, empty otherwise)
* ResourceMananger ("yes" if resource manager, empty otherwise)


###Config variables

In bulk-user-add.rb, set the following config variables:

* SS_TOKEN - Smartsheet API access token that belongs to an account administrator.  See the [Smartsheet API docs](http://smartsheet.com/developers) for help on how to generate acess tokens.

* CSV_FILE - name of the file containing the list of users to be created.

* EMAIL_DOMAINS - zero or more email domains.  If user's email address matches any of the domains, this utility will try to add the user to the organization, otherwise it will skip the user, print an error message and move on.  See the detailed discussion of EMAIL_DOMAINS below.

###Email domains

By default, Smartsheet has an opt-in account membership model - users cannot be added to a Smartsheet account without their explicit consent.  This means that when you attempt to add a user to your account, an email invitation is sent to the user's email address asking him/her to join.

Organizations that can prove their domain ownership via our domain validation process can bypass the invitation and user acceptance step, and add users without them getting notified or requiring them to take any action.

To add users to your Smartsheet account and bypass the invitation step:

* contact your Smartsheet account representative to add a domain record to your account - be prepared to provide proof of domain ownership
* once the domain record is in place, add the domain to the EMAIL_DOMAINS list

If you want to follow the standard user invitation and acceptance flow, don't worry about registering your domains with Smartsheet, and simply add them to EMAIL_DOMAINS list.


Usage
---

###Rate limit
Rate limit: The Smartsheet API enforces a rate limit of 300 calls per minute per access token (we reserve the right to change this rate, so please check the Smartsheet API docs to confirm).  The script is designed to gracefully handle the rate limit and will
sleep for 60 seconds before retrying whenever a rate limit error is encountered.

###Errors
If a non-fatal error is encountered, the utility will print a meaningful error message, skip the current user, and will continue to execute through the rest of the user list.  There are several scenarios when an attempt to add a user will fail:  

* You are attempting to add the user as a licensed sheet creator, and you have already exhausted the number of licensed allotted for your account
* You are attempting to add the user as a regular member (rather than a licensed sheet creator), and the user already owns one or more sheets - in that case, the user must be added as a licensed sheet creator
* The user is already a member of your account
* The user does not match any of your registered email domains
* The user is an existing Smartsheet user and belongs to another trial account
* The user is an existing Smartsheet user and belongs to another paid account

###Logging
Verbose status messages and errors are printed to output.  It is strongly recommended that you redirect your output to a log file in case you need to troubleshoot your batch.
