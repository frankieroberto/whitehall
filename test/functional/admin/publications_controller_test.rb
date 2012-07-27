require 'test_helper'

class Admin::PublicationsControllerTest < ActionController::TestCase
  setup do
    login_as :policy_writer
  end

  should_be_an_admin_controller

  should_allow_showing_of :publication
  should_allow_creating_of :publication
  should_allow_editing_of :publication
  should_allow_revision_of :publication

  should_show_document_audit_trail_for :publication, :show
  should_show_document_audit_trail_for :publication, :edit

  should_allow_related_policies_for :publication
  should_allow_organisations_for :publication
  should_allow_ministerial_roles_for :publication
  should_allow_attachments_for :publication
  should_allow_attached_images_for :publication
  should_not_use_lead_image_for :publication
  should_allow_association_between_countries_and :publication
  should_be_rejectable :publication
  should_be_publishable :publication
  should_be_force_publishable :publication
  should_be_able_to_delete_an_edition :publication
  should_link_to_public_version_when_published :publication
  should_not_link_to_public_version_when_not_published :publication
  should_prevent_modification_of_unmodifiable :publication

  test "new displays publication fields" do
    get :new

    assert_select "form#edition_new" do
      assert_select "select[name*='edition[publication_date']", count: 3
      assert_select "select[name='edition[publication_type_id]']"
      assert_select "input[name='edition[command_paper_number]'][type='text']"
      assert_select "input[name='edition[order_url]'][type='text']"
      assert_select "input[name='edition[price]'][type='text']"
    end
  end

  test "new should allow users to add publication metadata to an attachment" do
    get :new

    assert_select "form#edition_new" do
      assert_select "input[type=text][name='edition[edition_attachments_attributes][0][attachment_attributes][isbn]']"
      assert_select "input[type=text][name='edition[edition_attachments_attributes][0][attachment_attributes][unique_reference]']"
    end
  end

  test "create should create a new publication" do
    post :create, edition: controller_attributes_for(:publication,
      publication_date: Date.parse("1805-10-21"),
      command_paper_number: "Cm. 1234",
      order_url: "http://example.com/order-path",
      publication_type_id: PublicationType::ResearchAndAnalysis.id,
      price: "9.99"
    )

    created_publication = Publication.last
    assert_equal Date.parse("1805-10-21"), created_publication.publication_date
    assert_equal "Cm. 1234", created_publication.command_paper_number
    assert_equal "http://example.com/order-path", created_publication.order_url
    assert_equal PublicationType::ResearchAndAnalysis, created_publication.publication_type
    assert_equal 9.99, created_publication.price
  end

  test "create should create a new publication and attachment with additional publication metadata" do
    post :create, edition: controller_attributes_for(:publication).merge({
      edition_attachments_attributes: {
        "0" => { attachment_attributes: attributes_for(:attachment,
          title: "attachment-title",
          file: fixture_file_upload('greenpaper.pdf', 'application/pdf'),
          isbn: '0140621431',
          unique_reference: 'unique-reference')
        }
      }
    })

    created_publication = Publication.last
    assert_equal '0140621431', created_publication.attachments.first.isbn
    assert_equal 'unique-reference', created_publication.attachments.first.unique_reference
  end

  test "edit displays publication fields" do
    publication = create(:publication)

    get :edit, id: publication

    assert_select "form#edition_edit" do
      assert_select "select[name='edition[publication_type_id]']"
      assert_select "select[name*='edition[publication_date']", count: 3
      assert_select "input[name='edition[order_url]'][type='text']"
    end
  end

  test "edit should allow users to assign publication metadata to an attachment" do
    publication = create(:publication)
    attachment = create(:attachment)
    publication.attachments << attachment

    get :edit, id: publication

    assert_select "form#edition_edit" do
      assert_select "input[type=text][name='edition[edition_attachments_attributes][0][attachment_attributes][isbn]']"
      assert_select "input[type=text][name='edition[edition_attachments_attributes][0][attachment_attributes][unique_reference]']"
    end
  end

  test "update should save modified publication attributes" do
    publication = create(:publication)

    put :update, id: publication, edition: publication.attributes.merge(
      publication_date: Date.parse("1815-06-18"),
      order_url: "https://example.com/new-order-path"
    )

    saved_publication = publication.reload
    assert_equal Date.parse("1815-06-18"), saved_publication.publication_date
    assert_equal "https://example.com/new-order-path", saved_publication.order_url
  end

  test "should display publication attributes" do
    publication = create(:publication,
      publication_date: Date.parse("1916-05-31"),
      order_url: "http://example.com/order-path",
      publication_type_id: PublicationType::ResearchAndAnalysis.id
    )

    get :show, id: publication

    assert_select ".document" do
      assert_select ".publication_type", text: "Research and analysis"
      assert_select ".publication_date", text: "31 May 1916"
      assert_select "a.order_url[href='http://example.com/order-path']"
    end
  end

  test "should not display an order link if no order url exists" do
    publication = create(:publication, order_url: nil)

    get :show, id: publication

    assert_select ".document" do
      refute_select "a.order_url"
    end
  end
end
