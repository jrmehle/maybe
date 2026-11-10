require "application_system_test_case"

class CategoriesTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)
  end

  test "can create category" do
    visit categories_url
    click_link I18n.t("categories.new.new_category")
    fill_in "Name", with: "My Shiny New Category"
    click_button "Create Category"

    # The form submits asynchronously from a Turbo frame, so wait for the
    # submission (and its redirect) to complete before navigating away.
    assert_text "Category created successfully"

    visit categories_url
    assert_text "My Shiny New Category"
  end

  test "trying to create a duplicate category fails" do
    visit categories_url
    click_link I18n.t("categories.new.new_category")
    fill_in "Name", with: categories(:food_and_drink).name
    click_button "Create Category"

    assert_text "Name has already been taken"
  end
end
