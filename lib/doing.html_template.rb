DOING_STYLE=<<-EOSTYLE
body
{
  background:#fff;
  color:#333;
  font-family:Helvetica,arial,freesans,clean,sans-serif;
  font-size:16px;
  line-height:120%;
  padding:20px;
  text-align:justify;
}

h1
{
  left:220px;
  margin-bottom:1em;
  position:relative;
  text-align:left;
}

ul
{
  left:170px;
  list-style-position:outside;
  margin-right:170px;
  position:relative;
  text-align:left;
}

ul li
{
  border-left:solid 1px #ccc;
  line-height:2;
  list-style-type:none;
  padding-left:10px;
}

ul li .date
{
  color:#7d9ca2;
  font-size:14px;
  left:-82px;
  line-height:2;
  position:absolute;
  text-align:right;
  width:110px;
}

ul li .tag
{
  color:#999;
}

ul li .note
{
  color:#666;
  display:block;
  font-size:15px;
  line-height:1.4;
  padding:0 0 0 22px;
}

ul li .note:before
{
  color:#aaa;
  content:'\\25BA';
  font-size:8px;
  font-weight:300;
  left:40px;
  line-height:3;
  position:absolute;
}

ul li:hover .note
{
  display:block;
}

ul li .section
{
  color: #dbbfad;
  border-left: solid 1px #dbbfad;
  border-right: solid 1px #dbbfad;
  border-radius: 25px;
  padding: 0 4px;
  line-height: 1!important;
  font-size: .8em;
}

ul li .section:hover
{
  color: #c5753f;
}

ul li a:link {
  color: #64a9a5;
  text-decoration: none;
  background-color: rgba(203, 255, 251, .15);
}
EOSTYLE

DOING_TEMPLATE=<<EOHAML
!!!
%html
  %head
    %meta{"charset" => "utf-8"}/
    %meta{"content" => "IE=edge,chrome=1", "http-equiv" => "X-UA-Compatible"}/
    %title what are you doing?
    %style= @DOING_STYLE
  %body
    %header
      %h1= @page_title
    %article
      %ul
        - @items.each do |i|
          %li
            %span.date= i[:date]
            = i[:title]
            - if i[:note]
              %span.note= i[:note].map{|n| n.strip }.join('<br>')
EOHAML
