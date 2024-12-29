df=DataFrame()
df[!,:Class]=rand(["A","B","C"],10)
df[!,:Text]=rand(["ABC","DEF","GHI"],10)
df[!,:Value]=rand(10).*10000 .-5000

@css ".custom_css" Dict("background-color"=>"lightcyan","font-weight"=>"bold")
@el(st,"v-text-field",label="Search")
@el(d1,"v-data-table",items=df,binds=Dict("search"=>"st.value"),row-props="cond_form",cols=3,density="comfortable")

@el(sel,"v-select",label="Filter Class",items=["","A","B","C"],cols=1.2,update="filter_dt(d2,'Class',sel.value)")
@el(rs,"v-range-slider",label="Filter Value",thumb-label=true,value=[-5000,5000],class="pt-4",min=-5000,max=5000,cols=1.8,update="filter_dt(d2,'Value',rs.value)")
@el(d2,"v-data-table",items=df,filter=Dict("Class"=>"==","Value"=>"range"),cols=3,density="comfortable")

df[!,:Action]=df[!,:Text]
@el(alert,"v-alert",type="success",cols=3)
@el(btn,"v-btn",content="{{item.Text}}",binds=Dict("color"=>"item.Value<0 ? 'red' : 'blue'"),click="alert.text=item.Text;alert.value=true")
@el(d3,"v-data-table",items=df,col_template=Dict("Action"=>btn),cols=3,density="comfortable")

page([[[st,d1],spacer(),[[sel,rs],d2],spacer(),[spacer(rows=4),d3,alert]]],
    methods=Dict("cond_form"=>"""function(data){return data.item.col_value<0 ? {class:'custom_css'} : {} }"""))   