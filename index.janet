(bagatto/set-output-dir! "site")
(bagatto/set-defaults! {:attrs bagatto/parse-mago})

(def data {:meta {:src "meta.jdn" :attrs bagatto/parse-jdn}
           :css {:src (bagatto/slurp-* "assets/css/*.css")
                 :attrs bagatto/parse-base}
           :js {:src (bagatto/* "assets/js/main.js")
                :attrs bagatto/parse-base}
           :fonts {:src (bagatto/slurp-* "fonts/*.woff2")
                   :attrs bagatto/parse-base}
           :resume-pdf {:src (bagatto/* "assets/Resume-2023.pdf")
                        :attrs bagatto/parse-base}
           :resume {:src (bagatto/slurp-* "pages/resume.md")}
           :about {:src "pages/about.md"}
           :til {:src (bagatto/slurp-* "pages/til.md")}
           :blog-posts {:src (bagatto/slurp-* "pages/blog/*.md")}})

(def site {:static {:each :css
                    :dest (bagatto/path-copier "static")}
           :index {:dest "index.html"
                   :out (bagatto/renderer "/templates/index")}
           :about {:dest "about.html"
                   :out (bagatto/renderer "/templates/about")}
           :blog {:dest "blog.html"
                  :out (bagatto/renderer "/templates/blog")}
           :fonts-static {:each :fonts
                          :dest (bagatto/path-copier "static/fonts")}
           :resume-pdf {:each :resume-pdf
                        :dest (bagatto/path-copier "static")}
           :resume {:each :resume
                    :dest "resume.html"
                    :out (bagatto/renderer "/templates/resume")}
           :til {:each :til
                 :dest "til.html"
                 :out (bagatto/renderer "/templates/til")}
           :posts {:each :blog-posts
                   :dest (bagatto/%p "posts" '%i :title '% ".html")
                   :out (bagatto/renderer "/templates/post")}
           # :ex {:dest "out.html" :out (bagatto/renderer "/templates/ex")}
})
