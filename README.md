# THONAR
Interactive AR experience at Penn State Children’s Hospital for patients unable to attend events leading up to and including THON weekend

## Cloning repository

### Step 1: Connect your GitHub account to Xcode
Open up Xcode, but do not open up any projects or create a new project. Instead, in the menu, select *Xcode* -> *Preferences*. Within preferences, go to *Accounts* and add your GitHub account.

### Step 2: Clone the GitHub repository
Exit out of preferences and open Xcode again. Then click on *Clone an existing project* and click on the THONAR project.

## Adding a new feature to the project

### Step 1: Create a new branch off of master in GitHub
Call it feature/(name_of_feature) for consistency and to help everyone know what you are adding.

### Step 2: Update the status of your local repository
In the Xcode project, select *Source Control* -> *Fetch and Refresh Status*. You should now see the branch you created on GitHub in the Remotes folder in the Source Navigtor.

### Step 3: Add and commit your changes
To commit your changes in Xcode, select *Source Control* -> *Commit*. Then add a description about what you added to the project.

### Step 4: Push your commits from your local repository to the correct branch
Select *Source Control* -> *Push*. Then, select the branch coordinating to the feature that you are adding.

### Step 5: Merge the branch with the master branch
Go to GitHub and submit a pull request for the branch you want to merge. You can add a description if you think it will be helpful to others who are reviewing it. The pull requests automatically require at least one other contributor to review the requested changes in order for it to be merged with master to ensure master is always working properly.
