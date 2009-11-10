class GoogledocsController < ApplicationController

  DOCLIST_SCOPE = 'http://docs.google.com/feeds/'
  DOCLIST_DOWNLOD_SCOPE = 'http://docs.googleusercontent.com/'
  SPREADSHEETS_SCOPE = 'http://spreadsheets.google.com/feeds/'

  DOCLIST_FEED = DOCLIST_SCOPE + 'documents/private/full'
  FOLDER_FEED =  DOCLIST_SCOPE + 'folders/private/full'

  DOCUMENT_DOC_TYPE = 'document'
  FOLDER_DOC_TYPE = 'folder'
  PRESO_DOC_TYPE = 'presentation'
  PDF_DOC_TYPE = 'pdf'
  SPREADSHEET_DOC_TYPE = 'spreadsheet'
  MINE_LABEL = 'mine'
  STARRED_LABEL = 'starred'
  TRASHED_LABEL = 'trashed'

  MAX_CONTACTS_RESULTS = 500  

  before_filter :setup_client
  before_filter :find_project, :authorize

  # List all documents with links to edit in googledocs.
  def list

    @projid = params[:project_id]
    
    # Check that the project folder exists, if not, then create it
    uri = DOCLIST_FEED + '?title=' + URI.escape(@project.identifier) + '&showfolders=true'
    projectfolderfeed = @client.get(uri).to_xml
    if !projectfolderfeed.elements['entry']
      newfolderfeed = "<?xml version='1.0' encoding='UTF-8'?>"
      newfolderfeed << '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">'
      newfolderfeed << '<atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/docs/2007#folder" label="folder"/>'
      newfolderfeed << '<atom:title>' + @project.identifier + '</atom:title>'
      newfolderfeed << '</atom:entry>'
      @client.post(DOCLIST_FEED,newfolderfeed)
    end
    
    # GET all documents for the project folder.
    uri = DOCLIST_FEED + '/-/' + @project.identifier
    @docfeed = @client.get(uri).to_xml

    # GET all sub-folders of the project
    uri = DOCLIST_FEED + '/-/folder/' + URI.escape(@project.identifier)
    @subfeed = @client.get(uri).to_xml

    # @outxml = Array.new
    # GET documents in each subfolder
    @documents = {}
    @subfeed.elements.each('entry') do |subentry|
      #uri = DOCLIST_FEED + '/-/' + URI.escape(subentry.elements['title'].text)
      uri = FOLDER_FEED + '/' + URI.escape(subentry.elements['id'].text[/full\/(.*%3[aA].*)$/, 1])
      @subdocfeed = @client.get(uri).to_xml
      # @outxml.push @subdocfeed
      @documents[subentry.elements['title'].text] = Array.new
      @subdocfeed.elements.each('entry') do |entry|
        doc = {}
        doc['title'] = entry.elements['title'].text
        doc['id'] = entry.elements['id'].text
        doc['type'] = entry.elements['category'].attribute('label').value
        doc['publishedtime'] = entry.elements['published'].text[/(.*)T(.*)\..*Z/,2]
        doc['publisheddate'] = entry.elements['published'].text[/(.*)T(.*)\..*Z/,1]
        doc['updatedtime'] = entry.elements['updated'].text[/(.*)T(.*)\..*Z/,2] 
        doc['updateddate'] = entry.elements['updated'].text[/(.*)T(.*)\..*Z/,1]
        doc['etag'] = entry.attribute('etag').value
        # Parse out the alternate link for editing in google docs
        links = {}
        entry.elements.each('link') do |link|
          links[link.attribute('rel').value] = link.attribute('href').value
        end
        doc['altedit'] = links['alternate']
        doc['edit'] = links['edit']
        @documents[subentry.elements['title'].text].push doc
      end
    end
  end

  # Open a file for editing in googledocs
  def edit
    @iframe_text = '<iframe src="' + params[:altlink] + '" width="100%" height="800">
  <p>Your browser does not support iframes.</p>
</iframe>'
  end

  # Delete a file on google docs. Call this action with :check => 'True' to
  # confirm delete operation first before proceeding.
  def delete
    if params[:check] == 'True' then
        @projid = params[:project_id]
        @docid = params[:docid]
        @etag = params[:etag]
    else
        # delete the file
        @client.headers['If-Match'] = params[:etag]
        @client.delete(params[:docid])
        redirect_to :action => 'list', :project_id => @project
    end
  end

  # Create a new document. Documents are created in subfolders correspodning to
  # the document categories defined in redmine. If the subfolder does not exist
  # in google docs it is created.
  def new
    # Build the xml feed for gdata and then post.
    @newfeed = "<?xml version='1.0' encoding='UTF-8'?>"
    @newfeed << '<entry xmlns="http://www.w3.org/2005/Atom">'
    @newfeed << '<category scheme="http://schemas.google.com/g/2005#kind" '
    case params[:document]['type_id']
    when '1'
      @newfeed << 'term="http://schemas.google.com/docs/2007#document"/>'
    when '2'
      @newfeed << 'term="http://schemas.google.com/docs/2007#spreadsheet"/>'
    when '3'
      @newfeed << 'term="http://schemas.google.com/docs/2007#presentation"/>'
    when '4'
      @newfeed << 'term="http://schemas.google.com/docs/2007#form"/>'
    else
      @newfeed << 'term="http://schemas.google.com/docs/2007#nomatch"/>'
    end
    @newfeed << '<title>' + params[:document]['title'] + '</title>'

    # Get the uri for the selected category
    id = params[:document]['category_id']
    name = Enumeration.get_values('DCAT').find_all {|c| c.id.to_s == id}

    # Close the entry
    @newfeed << '</entry>'

    # Search for existing subfolder
    foundcat = false
    uri = DOCLIST_FEED + '/-/folder/' + URI.escape(@project.identifier)
    folderfeed = @client.get(uri).to_xml
    folderfeed.elements.each('entry') do |entry|
      # Create the document in the subfolder if it exists.
      if entry.elements['title'].text == name[0].to_s then
        folderid = entry.elements['id'].text[/full\/(.*%3[aA].*)$/, 1]
        uri = FOLDER_FEED + '/' + folderid
        @client.post(URI.escape(uri),@newfeed)
        foundcat = true
      end
    end

    # Create the folder and document if the folder did not already exist
    if !foundcat then
      uri = DOCLIST_FEED + '?title=' + URI.escape(@project.identifier) + '&showfolders=true'
      projectfolderfeed = @client.get(uri).to_xml
      projectfolderid = FOLDER_FEED + '/' +  projectfolderfeed.elements['entry'].elements['id'].text[/full\/(.*%3[aA].*)$/, 1]
      newfolderfeed = "<?xml version='1.0' encoding='UTF-8'?>"
      newfolderfeed << '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">'
      newfolderfeed << '<atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/docs/2007#folder" label="folder"/>'
      newfolderfeed << '<atom:title>' + name[0].to_s + '</atom:title>'
      newfolderfeed << '</atom:entry>'
      @client.post(URI.escape(projectfolderid),newfolderfeed)

      # Create the document
      foundcat = false
      uri = DOCLIST_FEED + '/-/folder'
      folderfeed = @client.get(uri).to_xml
      folderfeed.elements.each('entry') do |entry|
        if entry.elements['title'].text == name[0].to_s then
          folderid = entry.elements['id'].text[/full\/(.*%3[aA].*)$/, 1]
          uri = FOLDER_FEED + '/' + folderid
          @client.post(URI.escape(uri),@newfeed)
          foundcat = true
        end
      end
    end

    # Go back to the document list
    redirect_to :action => 'list', :project_id => @project

  end

private

  # gdata client login
  def setup_client
    scopes = [DOCLIST_SCOPE, DOCLIST_DOWNLOD_SCOPE,
              SPREADSHEETS_SCOPE]
    @client = GData::Client::DocList.new({:source => 'jaffeweb_redmine'})
    @client.clientlogin('your_google_email', 'your_password')
  end

  # Pull in project menus.
  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end

end
