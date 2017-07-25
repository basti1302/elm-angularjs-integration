# Elm-AngularJS-Integration

! This is experimental !

! This is work in progress !


This package lets you embed AngularJS directives into an Elm application and keeps the values in your Elm model in synch with the values in the embedded AngularJS directives. You might think "Whoa, that's a terrible idea". This is certainly true for greenfield projects.

The intended use case for this package are large existing AngularJS 1.x applications that want to introduce Elm. Writing new parts of the application in Elm and leaving the existing AngularJS parts relatively untouched might be one way to do that. Migrate the app gradually from AngularJS to Elm might be another situation where this package can be useful. In both cases, you may have already invested considerable time into writing reusable AngularJS directives (like complicated or fancy input components) that you do not want to re-implement from scratch in Elm, at least not immediately. This package gives you the option to write your application logic in Elm while still reusing your "legacy" AngularJS directives.

A typical usage would be an AngularJS application with some embedded Elm parts in which small pieces of AngularJS are embedded. (Yes, there is a bit of inception going on here - embedding AngularJS in Elm embedded in AngularJS).

This is a native package (it contains a native Elm module) and as such, comes with all the tradeoffs of native Elm packages (potential for run time errors).

The example app is based on <https://github.com/preboot/angularjs-webpack>.

## Running The Example App

After you have installed all dependencies you can now run the app with:
```bash
npm install
npm start
```

It will start a local server using `webpack-dev-server` which will watch, build (in-memory), and reload for you. The port will be displayed to you as `http://localhost:8080`.

## Developing

### Build files

* single run: `npm run build`
* build files and watch: `npm start`

## Testing

#### 1. Unit Tests

* single run: `npm test`
* live mode (TDD style): `npm run test-watch`

# License

[MIT](/LICENSE)
