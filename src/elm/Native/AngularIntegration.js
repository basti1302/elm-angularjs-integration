var _basti1302$elm_angularjs_integration$Native_AngularIntegration = function($, moment) {

  'use strict';

  if (typeof $ === 'undefined') {
    throw new Error('Elm-AngularJS-integration requires jQuery.');
  }

  var registry = {};
  var cleanUpTimeStamp = null;

  function embed(virtualDomNode, currentValue) {
    // Schedule a cleanup run. Since this happens for every embedded directive in each view cycle, we might end up with a lot
    // of cleanup calls per animation frame. The cleanup function takes care of doing the cleanup only once per animation
    // frame.
    requestAnimationFrame(doCleanUp);

    // Note. The virtualDomNode we receive here is a virtual DOM node in Elm's virtual DOM. It is not an actual existing DOM
    // node yet, so we can not embed an Angular directive directly into it. Instead, we prepare the required DOM manipulation
    // here and defer the actual embedding or updating via requestAnimationFrame.
    var registryId = virtualDomNode.facts.id;

    // Check if this particular AngularJS directive has already been embedded into the DOM.
    var existsInDom = domElementExists(registryId);
    var registryEntry = registry[registryId];
    if (registryEntry && existsInDom) {
      // The element is present in the registry and in the current DOM. This AngularJS directive has been compiled and
      // embedded already, we might need to update it with the current value coming out of the Elm model.
      updateEmbedded(registryId, registryEntry, currentValue);
      return virtualDomNode;
    } else if (!registryEntry && !existsInDom) {
      // This element is neither in the registry nor in the DOM. This AngularJS directive has not yet been embedded, we need
      // to compile the markup and put the result in the DOM.
      return embedNew(registryId, virtualDomNode, currentValue);
    } else if (registryEntry && !existsInDom) {
      // This element is in the registry but not in the current DOM. It has been compiled and embedded before, but the DOM
      // element has been removed in the meantime, so the registry entry is stale. Possible reason: The user navigated to
      // a different page and is now returning to a page where this element should be active. We need to clean up the old,
      // stale registry entry and embed a new instance of this element.
      doCleanUpForEntry(registryId, registryEntry);
      return embedNew(registryId, virtualDomNode, currentValue);
    } else {
      console.log('Error: Found an element that is in the DOM but not in the registry. This should not happen.',
        registryId);
    }
  }

  function updateEmbedded(registryId, registryEntry, newValue) {
    // console.log('EAI [', registryId, ']: Checking if a scope update is required.');
    var lastJsValue = registryEntry.lastJsValue;

    if (!registryEntry.scope || !registryEntry.scopeKey) {
      // console.log('EAI [', registryId, ']: No scope update due to missing scope or scopeKey, dropping value', newValue);
      return;
    }

    if (angular.equals(newValue, lastJsValue)) {
      // Avoid duplicate updates and cyclic infinite update ping-pong between Elm model and AngularJS scope. If both values
      // are already equal, do not update the scope or the $watch will fire again.
      // console.log('EAI [', registryId, ']: *NO* scope update is required, old value:', lastJsValue, ', new value:', newValue);
      return;
    } /* else {
            console.log('EAI [', registryId, ']: Scope update *IS* required, old value:', lastJsValue, ', new value:', newValue);
        } */

    registryEntry.scope[registryEntry.scopeKey] = newValue;
    registryEntry.scope.$digest();
  }

  function embedNew(registryId, virtualDomNode, currentValue) {
    // Maybe we should queue all embedNew calls for one view cycle and embed all of them after the next animation frame? Not
    // sure how we could schedule the final call to actually embed stuff as the last action in the view cycle, though.

    // The embed function is triggered while we are creating our view in Elm, that is, while the virtual DOM is being created.
    // We need to wait for the next animation frame to make sure the *actual* DOM element in which we want to embed has been
    // created.
    requestAnimationFrame(function() {
      injectAngularDirective(registryId, currentValue);
    });

    return virtualDomNode;
  }

  function injectAngularDirective(registryId, currentValue) {
    // console.log('EAI [', registryId, ']: Initial injection of directive with value:', currentValue);
    var targetDomElement = getDomElement(registryId);
    if (targetDomElement.length === 0) {
      console.log('Error: Coud not find element', registryId);
      return;
    } else if (targetDomElement.length !== 1) {
      console.log('Error: Coud not find unique element for ' + registryId +
        '. There are ' + targetDomElement.length + ' matching elements.');
      return;
    }

    var scopeKey = targetDomElement.attr('data-scope-key');
    var markup = targetDomElement.attr('data-markup');
    var isDate = targetDomElement.attr('data-is-date') === 'true';

    var watchFunction = function(newValue, oldValue) {
      // console.log('EAI [', registryId, ']: $watch fired, new value:', newValue, ', old value:', oldValue);

      // For dates (represented numerical as milliseconds since epoch) we need to translate between browser dates
      // (which are always in local time according to browser locale) and elm-community/elm-time, which is utc based.
      if (isDate && typeof newValue === 'number') {
        newValue = convertLocalDateToUtcDate(newValue);
      }

      if (newValue !== oldValue) {
        // console.log('EAI [', registryId, ']: Triggering update of Elm model due to $watch being triggered.');
        var registryEntryInWatchFunction = registry[registryId];
        if (registryEntryInWatchFunction) {
          registryEntryInWatchFunction.lastJsValue = newValue;
        }

        // When the Elm virtual DOM module calls the handler, it passes the JavaScript event (Mouse event or similar)
        // into the event handler function. Whatever we pass in here needs to be decoded in Elm, by the decoder used for
        // the "on" event listener on the virtual DOM element. If the decoding fails, it fails silently in the internals
        // of the Elm runtime, so there is no way to notify the client code about it. If you are missing update messages
        // in Elm that should have been triggered by you directive, your best bet currently is to set a breakpoint on the
        // next line, steop into the function call and check the decoded value for the decoding error message.
        targetDomElement[0].elm_handlers.embedded_watch_triggered(newValue);
      } /* else {
                console.log('EAI [', registryId, ']: Ignoring $watch event because values are the same.');
            } */
    };

    angular.element(targetDomElement).injector().invoke(['$compile', function($compile) {
      var targetScope = angular.element(targetDomElement).scope();
      var childScope = targetScope.$new();

      // register directive and child scope so we can update the directive in the next view cycle
      registry[registryId] = {
        id: registryId,
        scope: childScope,
        scopeKey: scopeKey,
        lastJsValue: currentValue
      };

      if (scopeKey) {
        childScope[scopeKey] = currentValue;
      }
      var directiveElement = $(markup);

      // remove all children of target DOM element before embedding into it
      targetDomElement.empty();

      // embed compiled Angular directive into target DOM element
      targetDomElement.append($compile(directiveElement)(childScope));

      // First, register the watch function
      if (scopeKey && watchFunction) {
        childScope.$watch(scopeKey, watchFunction);
      }

      // Second, trigger AngularJS' digest cycle once via $apply, so that our initial value is put into  Angulars' internal
      // "last committed value" - this ensures that the oldValue parameter passed into the $watch function on the first
      // change is set correctly).
      childScope.$apply();
    }]);
  }

  function doCleanUp(timeStamp) {
    // Make sure we only run clean up once per requestAnimationFrame, although it is triggered once per embedded element.
    if (cleanUpTimeStamp === timeStamp) {
      return;
    }
    cleanUpTimeStamp = timeStamp;

    // Find elements that are still in the registry of embedded elements but no longer in the actual DOM.
    for (var registryId in registry) {
      var registryEntry = registry[registryId];
      if (!domElementExists(registryId)) {
        doCleanUpForEntry(registryId, registryEntry);
      }
    }
  }

  function doCleanUpForEntry(registryId, registryEntry) {
    if (registryEntry.scope) {
      registryEntry.scope.$destroy();
    }
    delete registry[registryId];
  }

  function getDomElement(registryId) {
    return $('#' + registryId);
  }

  function domElementExists(registryId) {
    return getDomElement(registryId).length !== 0;
  }

  function convertLocalDateToUtcDate(date) {
    if (typeof date === 'number') {
      var m = moment(date);
      var asUtcBasedDate = moment.utc({
        year: m.year(),
        month: m.month(),
        day: m.date()
      });
      return asUtcBasedDate.valueOf();
    }
    return date;
  }

  return {
    // Note on F2: JS functions which take one argument can be returned as is, functions which take two arguments need to be
    // wrapped in F2, functions which take 3 arguments by wrapping them in F3, and so on. This ensures that currying them in
    // Elm works as expected. F2, F3, ... are provided by the Elm run time.
    embed: F2(embed)
  };

}(window.jQuery);
