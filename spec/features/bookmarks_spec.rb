require 'spec_helper'

describe "Bookmarks" do
  describe "navigating from the homepage" do
    it "should have a link to the history page" do
      sign_in 'user1'
      visit root_path
      click_link 'Bookmarks'
      expect(page).to have_content 'You have no bookmarks'
    end
  end

  it "should clear bookmarks" do
    visit solr_document_path('2007020969')
    click_button 'Bookmark'
    click_link 'Bookmarks'
    click_link 'Clear Bookmarks'
    expect(page).to have_content 'Cleared your bookmarks.'
    expect(page).to have_content 'You have no bookmarks'
  end

  it "add and remove bookmarks from search results" do
    sign_in 'user1'
    visit root_path
    fill_in "q", with: 'Sumadhvavijayaḥ'
    click_button 'search'
    click_button 'Bookmark'
    expect(page).to have_content 'Successfully added bookmark.'
    fill_in "q", with: 'Sumadhvavijayaḥ'
    click_button 'search'
    click_button 'Remove bookmark'
    expect(page).to have_content 'Successfully removed bookmark.'
  end

  it "should add and delete bookmarks from the show page" do
    sign_in 'user1'
    visit solr_document_path('2007020969')
    click_button 'Bookmark'
    click_button 'Remove bookmark'
    expect(page).to have_content 'Successfully removed bookmark.'
  end

  it "should add bookmarks after a user logs in" do
    visit solr_document_path('2007020969')
    click_button 'Bookmark'
    sign_in 'user1'
    visit bookmarks_path
    expect(page).to have_button("Remove bookmark")
    expect(page).to have_content("Strong Medicine speaks")
  end

  it "should cite items in bookmarks" do
    visit solr_document_path('2007020969')
    click_button 'Bookmark'
    click_link 'Bookmarks'
    click_link 'Cite'
    expect(page).to have_content 'Strong Medicine speaks'
  end

  it "should cite items in current bookmarks page" do
    visit solr_document_path('2009373513')
    click_button 'Bookmark'

    visit solr_document_path('2007020969')
    click_button 'Bookmark'

    visit "/bookmarks?per_page=1"
    expect(page).to have_content 'Ci an zhou bian'
    expect(page).not_to have_content 'Strong Medicine speaks'

    click_link 'Cite'
    expect(page).to have_content 'Ci an zhou bian'
    expect(page).not_to have_content 'Strong Medicine speaks'

    visit "/bookmarks?per_page=1"
    click_link "2"
    expect(page).to have_content 'Strong Medicine speaks'

    click_link 'Cite'
    expect(page).to have_content 'Strong Medicine speaks'
    expect(page).not_to have_content 'Ci an zhou bian'
  end
end
