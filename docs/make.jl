using VueJS,HTTP,Sockets,JSON,DataFrames,Dates,Highlights

function docs()
    
    df_examples=DataFrame(Name=[],Link=[])
    
    include("examples.jl")
    for e in examples

        name=e[1] 
        ex=split(e[2],"\n")
        filter!(x->x!="",ex) 
        ex_display=join(deepcopy(ex),"\n")
        ioh=IOBuffer() 
        stylesheet(ioh, MIME("text/html"))
        ex_style=String(take!(ioh))
        ioh=IOBuffer() 
        highlight(ioh, MIME("text/html"), join(deepcopy(ex_display)), Lexers.JuliaLexer)
        ex_display="<div v-pre>"*String(take!(ioh))*"</div>"

        ex[end]="global p="*ex[end]

        for r in ex
            eval(Meta.parse(r))
        end 
        html_code=String(response(p).body)
        
        html_code=replace(html_code,"</style>"=>"</style>"*ex_style)
        html_code=replace(html_code,"<v-container fluid>"=>"<v-container fluid>"*ex_display)
        io = open("public/$(name).html", "w")
        println(io, html_code)
        close(io)
        name_url=replace(name," "=>"%20")
        push!(df_examples,(name, """https://antonioloureiro.github.io/VueJS.jl/$(name_url).html"""))
        
    end
    df_components=DataFrame(Component=[],Library=[],Value_Attr=[],Doc=[])
    @el(bt_doc,"v-btn",value="Doc",click="doc_el.value=item.doc;title_el.value=item.component;dial.active.value=true",small=true,outlined=true,color="indigo")
    @el(dt_components,"v-data-table",items=df_components,col_template=Dict("Doc"=>bt_doc),caption="Components",dense=true,items-per-page=50,cols=4)

    @el(doc_el,"v-text-field",value="",v-show="false")
    @el(title_el,"v-text-field",value="",v-show="false")
    @el(bt_close,"v-btn",value="Close",click="dial.active.value=false",small=true,outlined=true,color="indigo")

    dial=dialog("dial",[html("h2","",Dict("v-html"=>"title_el.value","align"=>"left"),cols=12),card([
                    html("div","",Dict("v-html"=>"doc_el.value","align"=>"left"),cols=12)],cols=12),bt_close],width=800)

    p1=page([[dt_components,spacer(),dt_live],dial,title_el,doc_el]);
    
    io = open("public/index.html", "w")
    println(io, VueJS.htmlstring(p1))
    close(io)
    
end

docs()
