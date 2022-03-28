Provides a Dart API for accessing the deviantART public endpoints.

## Features

Provides a paginator abstraction for the daily, popular, newest, tags, topics list, more like this, tag search and top
topics endpoints.  The returned JSON is parsed in to a Dart class representing the response.

- Generic iterator and paginator interface
- Dart objects that represent the JSON data with corresponding fromJson() methods;
  * Suggested
  * More Like This
  * Tagged
  * Topic
  * Popular
  * Newest
  * Browse

## Getting started

To get started register an application with the deviantART API here: https://www.deviantart.com/developers/.  Then
create a file named `creds.dart` in the lib folder of the project.  The format of this file is as follows:
```dart
const clientId = '<client_id>';
const clientSecret = '<client_secret>';
```

## Usage

```dart
final client = await ClientBuilder.build();
final paginator = client.dailyPaginator();
final response = await paginator.next();
```
