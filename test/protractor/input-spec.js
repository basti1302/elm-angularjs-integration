describe('simple string input', function() {

  beforeEach(function() {
    browser.get('');
    element(by.id('simple-string-ng')).clear();
    element(by.id('simple-string-elm')).clear();
  });

  it('ng -> angular', function() {
    element(by.id('simple-string-ng')).sendKeys('abc');
    expect(element(by.id('simple-string-elm')).getAttribute('value'))
      .toEqual('abc');
  });

  it('angular -> elm', function() {
    element(by.id('simple-string-elm')).sendKeys('def');
    expect(element(by.id('simple-string-ng')).getAttribute('value'))
      .toEqual('def');
  });

});
