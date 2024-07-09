#!/bin/sh

. ~/.scc-credentials

echo $SCC_PASSWORD | podman login -u $SCC_USER --password-stdin registry.suse.com
if test $? -ne 0; then
    exit 1
fi
echo $SCC_PASSWORD | skopeo login -u $SCC_USER --password-stdin registry.suse.com

images_path=registry.suse.com/suse/manager/5.0/

echo '[' >images-info.json
separator=

for image in `podman search --limit 100 --format '{{.Name}}' $images_path`; do
    case $image in
        *-helm) continue;;
    esac

    for tag in `skopeo inspect --format "{{.RepoTags}}" docker://$image | tr -d "[]"` ; do
        case $tag in
          *.sig|*.att) continue;;
        esac
        tagged_image="$image:$tag"
        if test "z$separator" != "z"; then
            echo "$separator" >>images-info.json
        fi
        echo    "  {" >>images-info.json
        echo    "    \"name\": \"$tagged_image\"," >>images-info.json
        echo    "    \"digest\": \"`skopeo inspect docker://$tagged_image --format '{{.Digest}}'`\"," >>images-info.json
        echo    "    \"created\": \"`skopeo inspect docker://$tagged_image --format '{{.Created}}'`\"" >>images-info.json
        echo -n "  }" >>images-info.json
        separator=,
    done
done
echo ']' >>images-info.json
