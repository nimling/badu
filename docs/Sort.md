# Customise Deployment Order

## The problem

Normally if you write a bicep file as a deployment, you would write it in such a way that whatever you want to be deployed first is both written at the the top of your file AND is a dependency (`dependOn`) within other resources, and that they again is a dependency for other resources, and so on.

While BADU wants you to split different deployments (or different parts of the same deployment) into different files, it makes is somewhat challenging for you to have control over the order of deployment. This is mostly because both windows and Linux lists files alphabetically, and not in the order you want them to be deployed.

## The solution

So in order to make sure you have better control, BADU has implemented a file called `sort`.
There is really nothing special aboput the file, it is just a file with a list of files and folders that you want to be deployed in a specific order.
The neat thing is that is supports [wildcards](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_wildcards?view=powershell-7.3), so if you have a folder called `01-rg` and a folder called `02-vnet` you can just write `01*` and it will match just `01-rg` and not `02-vnet`.

You normally don't really care about whats in the middle of your deployment order as long as the start and the end is correct, so in order to hande "the rest" you can write `...` and it will match everything that is not specified in the file.

* write the items you want to be deployed, in order
* write `...` if you don't care about the middle
* write the last items you want to be deployed, in order
* dont care about file suffixes. main(the folder), main.bicep and main.json is the same item in my eyes.
* only for the current folder, not subfolders
* each line (except `...`) supports [wildcards](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_wildcards?view=powershell-7.3#long-description)

## BETA INFO

With this, i will also group together deployments and run them at the same time. named deployment will be run first and last, but the `...` bucket will be run in parallel.

## Examples

Lets assume we have the current file structure:

```text
mysubscription
|
├─ Rg.bicep
|
├─ rg-public
│    ...
|
├─ rg-mywebsite
|    VideoStorage.bicep
|    ImageStorage.bicep
|    AnyWebApp.bicep
|    Keyvault.bicep
│
├─ rg-vnet
│    ...
```

We are seeing a subscription deployment

* `mysubscription` is the subscription deployment
* `rg.bicep` deploys all the resource groups
* `rg-mywebsite` deploys a website
* `rg-vnet` deploys all the networking
* `rg-public` deploys all the shared resources

### Example - Basic sort file

Firstly i want `rg.bicep` first, before anything else, so i create a new file: `sort` and write the following in it:

```text
Rg
```

if "`...`" is not specified i will assume it is the end of the list, so i dont need to write anything else.

this will result in the following order:

1. Rg
2. rg-mywebsite
3. rg-public
4. rg-vnet

### Example - Basic sort file 2

With the previous example, it didn't quite fit my needs, as i need two things to happen:

1. Vnet rg needs to be defined first, but after `rg.bicep`
2. Public rg needs to always go last

so i change the `sort` file to:

```text
Rg
rg-vnet
...
rg-public
```

this will result in the following deployment order:

1. Rg
2. rg-vnet
3. rg-mywebsite
4. rg-public

the added benefit here, is that if i add a new folder, lets say `rg-aks` it will be deployed after `rg-vnet` and before `rg-public` without you having to change the `sort` file.

### Example - Basic sort file 3

In the mywebsite folder i want the storage and keyvault to be deployed before the webapp, so i create a new file called `sort` and write the following in it:

```text
...
Webapp
```

this will result in the following deployment order:

* VideoStorage.bicep
* imagestorage.bicep
* keyvault.bicep
* AnyWebApp.bicep

### Example - Wildcards

* `*` - Match zero or more characters
  * `a*` matches `aA`, `ag`, and `Apple`
  * `a*` doesn't match `banana`
* `?` - Match one character in that position
  * `?n` matches `an`, `in`, and `on`
  * `?n` doesn't match `ran`
* `[ ]` - Match a range of characters
  * `[a-l]ook` matches `book`, `cook`, and `look`
  * `[a-l]ook` doesn't match `took`
* `[ ]` - Match specific characters
  * `[bc]ook` matches `book` and `cook`
  * `[bc]ook` doesn't match `hook`
* `` `* `` - Match any character as a literal (not a wildcard character)
  * ``12`*4`` matches `12*4`
  * ``12`*4`` doesn't match `1234`

---
(all credit for the idea of sort goes to [Lucas Geiter and his "Awesome pages" mkdoc plugin](https://github.com/lukasgeiter/mkdocs-awesome-pages-plugin))
