#!/bin/bash

input=""
output="3"
move="1"
js=md_auto_gen.js
#timestr=$(env LC_TIME=en_US.UTF-8 date "+%Y/%m/%d %H:%M:%S")
export NODE_PATH=/home/$USER/node_modules

usage()
{
    echo -e "\033[32mUsage:\033[0m"
    echo "    $0 -i <file> -o <num> -m <num>"
    echo "        -i: input markdown filename"
    echo "        -o: output choice, bit0: export HTML, bit1: export PDF, bit2: export EPUB"
    echo "        -m: move choice, 1: mv HTML+PDF+EPUB to html/pdf/epub folder, 0: not move"
    echo "    default is exporting HTML+PDF+EPUB from all markdown files in md folder, then move them to html/pdf/epub folder"
    echo -e "\033[32mDependency:\033[0m"
    echo "    nodejs + npm (for running JavaScript): sudo apt install nodejs npm gdebi"
    echo "    crossnote (https://github.com/shd101wyy/crossnote/) (core tool): npm install --save crossnote"
    echo "    chrome (for exporting PDF files): wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo gdebi google-chrome*.deb"
    echo "    calibre (for exporting epub files): sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin"
    echo "    Note: Maybe we should upgrade nodejs and npm to the latest version:"
    echo "        sudo npm cache clean -f   # Clean cache"
    echo "        sudo npm install n -g     # Install n module"
    echo "        sudo n stable             # Upgrade to lastest nodejs: 'stable' / 'lts' / 'latest'"
    echo "        sudo npm install npm -g   # Upgrade to lastest npm"
}

while getopts "i:o:m:h" args
do
    case $args in
        i)
            input=$OPTARG
            if [ ! -f $input ]; then
                echo "$input is not existed!"
                exit 1
            fi
            ;;
        o)
            output=$OPTARG
            ;;
        m)
            move=$OPTARG
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

cat <<'EOF' >$js
const { Notebook } = require('crossnote');

const [, , mdpath, mdname, choice] = process.argv;
mdchoice = parseInt(choice)

async function main() {
    const notebook = await Notebook.init({
        notebookPath: mdpath,
        config: {
            previewTheme: 'github-light.css',
            mathRenderingOption: 'KaTeX',
            codeBlockTheme: 'github.css',
            printBackground: true,
            enableScriptExecution: true, // <= For running code chunks.
        },
    });

    // Get the markdown engine for a specific note file in your notebook.
    const engine = notebook.getNoteMarkdownEngine(mdname);

    if (mdchoice & 1) {
        // html export
        await engine.htmlExport({ offline: false, runAllCodeChunks: true });
    }

    if (mdchoice & 2) {
        // chrome (puppeteer) export
        await engine.chromeExport({ fileType: 'pdf', runAllCodeChunks: true }); // fileType = 'pdf'|'png'|'jpeg'
    }

    if (mdchoice & 4) {
        // ebook export
        await engine.eBookExport({ fileType: 'epub' }); // fileType = 'epub'|'pdf'|'mobi'|'html'
    }

    // prince export
    // await engine.princeExport({ runAllCodeChunks: true });

    // pandoc export
    // await engine.pandocExport({ runAllCodeChunks: true });

    // markdown(gfm) export
    // await engine.markdownExport({ runAllCodeChunks: true });

    // open in browser
    // await engine.openInBrowser({ runAllCodeChunks: true });

    return process.exit();
}

main();
EOF

do_export()
{
    md=$1

    # export to html and pdf
    echo "export $md"
    node $js $(dirname $md) $(basename $md) $output

    # add timestamp
    if [[ $(( $output & 1 )) != "0" ]]; then
        html=${md%.*}".html"
        # Add to head of html
        # sed -i "s;<body for=\"html-export\">;<body for=\"html-export\"><p align=\"center\">$timestr</p>;" $html
        # Add to tail of html
        # sed -i "$ i <p align=\"center\">$timestr</p>" $html
    fi
}

if [[ -z $input ]]; then
    for file in `ls md/*.md`
    do
        do_export `realpath $file`
    done
else
    do_export `realpath $input`
fi

# move to html/pdf/epub folder
if [[ $move != "0" ]]; then
    savepath=../books
    if [[ $(( $output & 1 )) != "0" ]]; then
        mkdir -p $savepath/html
        mv md/*.html $savepath/html -f
    fi
    if [[ $(( $output & 2 )) != "0" ]]; then
        mkdir -p $savepath/pdf
        mv md/*.pdf $savepath/pdf
    fi
    if [[ $(( $output & 4 )) != "0" ]]; then
        mkdir -p $savepath/epub
        mv md/*.epub $savepath/epub
    fi

    mkdir -p $savepath/pic
    cp -rfp pic/* $savepath/pic
fi

rm $js
echo "Successful!"
