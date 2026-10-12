PS C:\VibeShopping> firebase init hosting

     ######## #### ########  ######## ########     ###     ######  ########
     ##        ##  ##     ## ##       ##     ##  ##   ##  ##       ##
     ######    ##  ########  ######   ########  #########  ######  ######
     ##        ##  ##    ##  ##       ##     ## ##     ##       ## ##
     ##       #### ##     ## ######## ########  ##     ##  ######  ########

You're about to initialize a Firebase project in this directory:

  C:\VibeShopping

Before we get started, keep in mind:

  * You are currently outside your home directory

✔ Are you ready to proceed? Yes

=== Project Setup

First, let's associate this project directory with a Firebase project.
You can create multiple project aliases by running firebase use --add,

✔ Please select an option: Use an existing project
✔ Select a default Firebase project for this directory: flutter1-b1fc8 (Flutter1)

=== Hosting Setup

Your public directory is the folder (relative to your project directory) that
will contain Hosting assets to be uploaded with firebase deploy. If you
have a build process for your assets, use your build's output directory.

✔ What do you want to use as your public directory? build/web
✔ Configure as a single-page app (rewrite all urls to /index.html)? Yes
✔ Set up automatic builds and deploys with GitHub? No
✔ File build\web\index.html already exists. Overwrite? No
i  Skipping write of build\web\index.html

+  Wrote configuration info to firebase.json
+  Wrote project information to .firebaserc

+  Firebase initialization complete!
PS C:\VibeShopping> firebase hosting:channel:list

Channels for site flutter1-b1fc8

┌────────────┬─────────────────────┬────────────────────────────────┬─────────────┐
│ Channel ID │ Last Release Time   │ URL                            │ Expire Time │
├────────────┼─────────────────────┼────────────────────────────────┼─────────────┤
│ live       │ 2026-08-18 22:19:22 │ https://flutter1-b1fc8.web.app │ never       │
└────────────┴─────────────────────┴────────────────────────────────┴─────────────┘
PS C:\VibeShopping> firebase use
Active Project: flutter1-b1fc8

Project aliases for C:\VibeShopping:

* default (flutter1-b1fc8)

Run firebase use --add to define a new project alias.
PS C:\VibeShopping> firebase use vibeshopping-4ffae
Now using project vibeshopping-4ffae
PS C:\VibeShopping> firebase use
Active Project: vibeshopping-4ffae

Project aliases for C:\VibeShopping:

  default (flutter1-b1fc8)

Run firebase use --add to define a new project alias.
PS C:\VibeShopping> firebase hosting:sites:list

Sites for project vibeshopping-4ffae

┌────────────────────┬────────────────────────────────────┬─────────────────┐
│ Site ID            │ Default URL                        │ App ID (if set) │
├────────────────────┼────────────────────────────────────┼─────────────────┤
│ vibeshopping-4ffae │ https://vibeshopping-4ffae.web.app │ --              │
└────────────────────┴────────────────────────────────────┴─────────────────┘
PS C:\VibeShopping> firebase use --add
✔ Which project do you want to add? vibeshopping-4ffae
✔ What alias do you want to use for this project? (e.g. staging) default

Created alias default for vibeshopping-4ffae.
Now using alias default (vibeshopping-4ffae)
PS C:\VibeShopping> firebase use
Active Project: default (vibeshopping-4ffae)

Project aliases for C:\VibeShopping:

* default (vibeshopping-4ffae)

Run firebase use --add to define a new project alias.
PS C:\VibeShopping> firebase deploy

=== Deploying to 'vibeshopping-4ffae'...

i  deploying hosting
i  hosting[vibeshopping-4ffae]: beginning deploy...
i  hosting[vibeshopping-4ffae]: found 38 files in build/web
⠹  hosting: uploading new files [31/38] (81%)
Error: Task 2997e83c53c3332c477b9abc59502a74a9afb5c20db1b37f5a25c6fa6d732800 failed: retries exhausted after 6 attempts, with error: TypeError: Converting circular structure to JSON
    --> starting at object with constructor 'Agent'
    |     property 'sockets' -> object with constructor 'Object'
    |     property 'upload-firebasehosting.googleapis.com:443:::::::::::::::::::::' -> object with constructor 'Array'
    |     ...
    |     property '_httpMessage' -> object with constructor 'ClientRequest'
    --- property 'agent' closes the circle
⠴  hosting: uploading new files [32/38] (84%)
PS C:\VibeShopping> firebase deploy

=== Deploying to 'vibeshopping-4ffae'...

i  deploying hosting
i  hosting[vibeshopping-4ffae]: beginning deploy...
i  hosting[vibeshopping-4ffae]: found 38 files in build/web
+  hosting[vibeshopping-4ffae]: file upload complete
i  hosting[vibeshopping-4ffae]: finalizing version...
+  hosting[vibeshopping-4ffae]: version finalized
i  hosting[vibeshopping-4ffae]: releasing new version...
+  hosting[vibeshopping-4ffae]: release complete

+  Deploy complete!

Project Console: https://console.firebase.google.com/project/vibeshopping-4ffae/overview
Hosting URL: https://vibeshopping-4ffae.web.app
PS C:\VibeShopping>
