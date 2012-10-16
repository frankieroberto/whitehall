jQuery(function($) {
  $("#notes_to_editors").addToggleLink(".notes_to_editors");
  $("abbr.time_ago").timeago();
  $('section.featured_items').equalHeightHelper({selectorsToResize: ['h2 a', 'p.summary', 'div.image_summary']});
  $('section.article_group').equalHeightHelper({selectorsToResize: ['article']});
  $('#featured-news-articles').equalHeightHelper({selectorsToResize: ['.img img']});
  $('.floated_list').equalHeightHelper({selectorsToResize: ['li']});
  $('.alphabetical-row').equalHeightHelper({selectorsToResize: ['li']});
  $('.js-toggle-change-notes').toggler();
  $('.js-hide-other-links').hideOtherLinks();
  $('.js-nav-helper').each(function () {
    $(this).find('.inner ul').append($.li('', '.st'));
  }).navHelper({
    breakpoints: [
      { width: 540, label: 'All sections', exclude: '.home, .current' },
      { width: 850, label: 'More sections', exclude: '.home, .current, .primary' }
    ],
    appendTo: '.js-nav-helper .inner li.st'
  });

  var inside_gov = $(".inside_gov_home");
  if(inside_gov.length != 0){
    $(".recently_updated").news_ticker();
  }
  $('section.featured_carousel').each(function () {
    $(this).addClass('slider');
    $(this).find('article').addClass('slide');
    $(this).wrap($.div('', '.slider_wrap'));
    $('.slider_wrap').carousel({
      slider: '.slider',
      slide: '.slide',
      addNav: true,
      addPagination: false,
      namespace: 'carousel',
      speed: 300 // ms.
    });
  });

  $('.document.body').enhanceYoutubeVideoLinks();

  $('.detailed-guides-show').trackExternalLinks();

  GOVUK.stickAtTopWhenScrolling.init();
  GOVUK.backToContent.init();

  $('.js-toggle-accessibility-warning').toggler({header: ".toggler", content: ".help-block"})

  $(".js-document-filter").enableDocumentFilter();

  $('.js-hide-extra-logos .organisations-icon-list .organisation').hideExtraRows({
    appendToParent: true,
    showWrapper: $('<li class="show-other-content" />')
  });

  // FIXME: use the `js-` prefix instead
  $('.organisations-show #ministers .ministerial_role').hideExtraRows();

  $('.organisations-show .management-secondary .board_member_role').hideExtraRows();

  $('.organisations-show #military .military_role').hideExtraRows();

  GOVUK.hideDepartmentChildren.init();

});
